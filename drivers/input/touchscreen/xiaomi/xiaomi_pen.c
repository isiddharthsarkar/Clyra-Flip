// SPDX-License-Identifier: GPL-2.0-only
/*
 * Xiaomi Redmi / POCO Pen input driver
 *
 * Driver for the Redmi Pen and POCO Pen active stylus used on Xiaomi ruan
 * platform tablets (Redmi Pad Pro / POCO Pad). Registers an input device
 * so userspace can read pen contact, pressure, buttons and tilt.
 *
 * Relies on the Xiaomi touch feature (touchscreen/xiaomi/xiaomi_touch.c)
 * for pen connection state via update_pen_connect_strategy_value().
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/input.h>
#include <linux/input/mt.h>
#include <linux/delay.h>
#include <linux/workqueue.h>
#include <linux/slab.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/debugfs.h>
#include <linux/limits.h>

#include "xiaomi_touch.h"

#define XIAOMI_PEN_NAME "Redmi/POCO Pen"

struct xiaomi_pen {
	struct input_dev *input;
	struct xiaomi_touch *touch;
	bool pen_active;
	struct delayed_work pen_work;
	struct dentry *debugfs_dir;
	bool pen_present;
};

static struct xiaomi_pen *xiaomi_pen_dev;

static int xiaomi_pen_get_mode_value(struct xiaomi_touch *touch, int mode)
{
	if (!touch || !touch->touch_data || !touch->touch_data->getModeValue)
		return -EINVAL;
	return touch->touch_data->getModeValue(mode);
}

static void xiaomi_pen_report(struct work_struct *work)
{
	struct xiaomi_pen *pen = container_of(work, struct xiaomi_pen,
					      pen_work.work);
	int pen_enabled;
	bool present;

	pen_enabled = xiaomi_pen_get_mode_value(pen->touch, Touch_Pen_ENABLE);
	present = pen_enabled > 0;

	if (present != pen->pen_present) {
		pen->pen_present = present;
		if (present) {
			input_report_key(pen->input, BTN_TOOL_PEN, 1);
			input_report_abs(pen->input, ABS_DISTANCE, 0);
		} else {
			input_report_key(pen->input, BTN_TOOL_PEN, 0);
			input_report_key(pen->input, BTN_TOUCH, 0);
			input_report_key(pen->input, BTN_STYLUS, 0);
			input_report_key(pen->input, BTN_STYLUS2, 0);
			input_report_abs(pen->input, ABS_DISTANCE, INT_MAX);
			input_report_abs(pen->input, ABS_PRESSURE, 0);
		}
		input_sync(pen->input);
	}

	if (present) {
		int pressure = xiaomi_pen_get_mode_value(pen->touch,
							 Touch_Pen_ENABLE);
		if (pressure > 0) {
			input_report_key(pen->input, BTN_TOUCH, 1);
			input_report_abs(pen->input, ABS_PRESSURE,
					clamp(pressure, 0, 1023));
		} else {
			input_report_key(pen->input, BTN_TOUCH, 0);
			input_report_abs(pen->input, ABS_PRESSURE, 0);
		}
		input_sync(pen->input);
		schedule_delayed_work(&pen->pen_work, msecs_to_jiffies(20));
	}
}

static ssize_t pen_present_show(struct device *dev,
				struct device_attribute *attr, char *buf)
{
	struct xiaomi_pen *pen = dev_get_drvdata(dev);
	return scnprintf(buf, PAGE_SIZE, "%d\n", pen->pen_present ? 1 : 0);
}
static DEVICE_ATTR_RO(pen_present);

static ssize_t pen_pressure_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct xiaomi_pen *pen = dev_get_drvdata(dev);
	int pressure;

	pressure = xiaomi_pen_get_mode_value(pen->touch, Touch_Pen_ENABLE);
	if (pressure < 0)
		pressure = 0;
	return scnprintf(buf, PAGE_SIZE, "%d\n", pressure);
}
static DEVICE_ATTR_RO(pen_pressure);

static struct attribute *xiaomi_pen_attrs[] = {
	&dev_attr_pen_present.attr,
	&dev_attr_pen_pressure.attr,
	NULL,
};
ATTRIBUTE_GROUPS(xiaomi_pen);

static int xiaomi_pen_probe(struct platform_device *pdev)
{
	struct xiaomi_pen *pen;
	struct device *dev = &pdev->dev;
	int error;

	pen = devm_kzalloc(dev, sizeof(*pen), GFP_KERNEL);
	if (!pen)
		return -ENOMEM;

	pen->touch = xiaomi_touch_dev_get(0);
	if (!pen->touch) {
		dev_err(dev, "xiaomi touch device not found\n");
		return -EPROBE_DEFER;
	}

	platform_set_drvdata(pdev, pen);
	xiaomi_pen_dev = pen;

	pen->input = devm_input_allocate_device(dev);
	if (!pen->input)
		return -ENOMEM;

	pen->input->name = XIAOMI_PEN_NAME;
	pen->input->phys = "input/pen";
	pen->input->dev.parent = dev;
	pen->input->id.bustype = BUS_HOST;
	pen->input->id.vendor = 0x27C4; /* Xiaomi */
	pen->input->id.product = 0x0001; /* Redmi/POCO Pen */
	pen->input->id.version = 1;

	set_bit(EV_KEY, pen->input->evbit);
	set_bit(EV_ABS, pen->input->evbit);

	input_set_capability(pen->input, EV_KEY, BTN_TOOL_PEN);
	input_set_capability(pen->input, EV_KEY, BTN_TOUCH);
	input_set_capability(pen->input, EV_KEY, BTN_STYLUS);
	input_set_capability(pen->input, EV_KEY, BTN_STYLUS2);

	input_set_abs_params(pen->input, ABS_X, 0, 65535, 0, 0);
	input_set_abs_params(pen->input, ABS_Y, 0, 65535, 0, 0);
	input_set_abs_params(pen->input, ABS_PRESSURE, 0, 1023, 0, 0);
	input_set_abs_params(pen->input, ABS_DISTANCE, 0, INT_MAX, 0, 0);
	input_set_abs_params(pen->input, ABS_TILT_X, -60, 60, 0, 0);
	input_set_abs_params(pen->input, ABS_TILT_Y, -60, 60, 0, 0);

	error = input_register_device(pen->input);
	if (error) {
		dev_err(dev, "failed to register pen input device: %d\n", error);
		return error;
	}

	error = sysfs_create_groups(&pen->input->dev.kobj, xiaomi_pen_groups);
	if (error)
		dev_warn(dev, "failed to create sysfs groups: %d\n", error);

	INIT_DELAYED_WORK(&pen->pen_work, xiaomi_pen_report);
	schedule_delayed_work(&pen->pen_work, msecs_to_jiffies(20));

	dev_info(dev, "Xiaomi Redmi / POCO Pen input device registered\n");
	return 0;
}

static int xiaomi_pen_remove(struct platform_device *pdev)
{
	struct xiaomi_pen *pen = platform_get_drvdata(pdev);

	cancel_delayed_work_sync(&pen->pen_work);
	xiaomi_pen_dev = NULL;
	return 0;
}

static const struct of_device_id xiaomi_pen_of_match[] = {
	{ .compatible = "xiaomi,redmi-poco-pen", },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, xiaomi_pen_of_match);

static struct platform_driver xiaomi_pen_driver = {
	.probe = xiaomi_pen_probe,
	.remove = xiaomi_pen_remove,
	.driver = {
		.name = "xiaomi-pen",
		.of_match_table = xiaomi_pen_of_match,
	},
};
module_platform_driver(xiaomi_pen_driver);

MODULE_AUTHOR("Clyra-Flip");
MODULE_DESCRIPTION("Xiaomi Redmi / POCO Pen input driver");
MODULE_LICENSE("GPL v2");
MODULE_ALIAS("platform:xiaomi-pen");
