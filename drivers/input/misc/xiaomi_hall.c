// SPDX-License-Identifier: GPL-2.0-only
/*
 * Lid (keyboard cover) sensor for Xiaomi tablets such as ruan.
 *
 * The ADSP watches the hall sensor and raises two SMP2P interrupts on the
 * "mi_hall_lid" entry: open_irq and close_irq. Each child of the
 * "xiaomi-hall" node describes one sensor with those interrupts, its
 * input type and code (EV_SW / SW_LID) and the sensor pin, which gives
 * the state at probe. Xiaomi's driver was never published; this follows
 * the stock device tree.
 */
#include <linux/gpio.h>
#include <linux/gpio/consumer.h>
#include <linux/of_gpio.h>
#include <linux/input.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_irq.h>
#include <linux/platform_device.h>

struct xiaomi_hall_sensor {
	struct input_dev *input;
	struct gpio_desc *pin;
	unsigned int type;
	unsigned int code;
	int open_irq;
	int close_irq;
};

static irqreturn_t xiaomi_hall_irq(int irq, void *data)
{
	struct xiaomi_hall_sensor *s = data;
	int closed = (irq == s->close_irq);

	input_event(s->input, s->type, s->code, closed);
	input_sync(s->input);
	return IRQ_HANDLED;
}

static int xiaomi_hall_add(struct device *dev, struct device_node *np)
{
	struct xiaomi_hall_sensor *s;
	const char *label = np->name;
	u32 flags = 0;
	int gpio, ret;

	s = devm_kzalloc(dev, sizeof(*s), GFP_KERNEL);
	if (!s)
		return -ENOMEM;

	of_property_read_string(np, "label", &label);
	if (of_property_read_u32(np, "linux,input-type", &s->type))
		s->type = EV_SW;
	if (of_property_read_u32(np, "linux,code", &s->code))
		s->code = SW_LID;

	s->open_irq = of_irq_get_byname(np, "open_irq");
	s->close_irq = of_irq_get_byname(np, "close_irq");
	if (s->open_irq == -EPROBE_DEFER || s->close_irq == -EPROBE_DEFER)
		return -EPROBE_DEFER;
	if (s->open_irq <= 0 || s->close_irq <= 0) {
		dev_err(dev, "%s: no open/close interrupts\n", label);
		return -EINVAL;
	}

	/* "hall_pin" is not a standard GPIO property name */
	gpio = of_get_named_gpio(np, "hall_pin", 0);
	if (gpio == -EPROBE_DEFER)
		return -EPROBE_DEFER;
	if (gpio_is_valid(gpio) &&
	    !devm_gpio_request_one(dev, gpio, GPIOF_IN, label)) {
		s->pin = gpio_to_desc(gpio);
		if (of_property_read_u32_index(np, "hall_pin", 2, &flags) == 0 &&
		    (flags & 1))
			gpiod_toggle_active_low(s->pin);
	}

	s->input = devm_input_allocate_device(dev);
	if (!s->input)
		return -ENOMEM;
	s->input->name = "xiaomi-hall";
	s->input->phys = "xiaomi-hall/input0";
	s->input->id.bustype = BUS_HOST;
	input_set_capability(s->input, s->type, s->code);

	ret = input_register_device(s->input);
	if (ret)
		return ret;

	/* The pin reads 1 (active low) while the cover is closed */
	if (s->pin) {
		input_event(s->input, s->type, s->code,
			    !!gpiod_get_value_cansleep(s->pin));
		input_sync(s->input);
	}

	ret = devm_request_threaded_irq(dev, s->open_irq, NULL, xiaomi_hall_irq,
					IRQF_TRIGGER_RISING | IRQF_ONESHOT,
					"hall_open", s);
	if (ret)
		return ret;
	ret = devm_request_threaded_irq(dev, s->close_irq, NULL, xiaomi_hall_irq,
					IRQF_TRIGGER_RISING | IRQF_ONESHOT,
					"hall_close", s);
	if (ret)
		return ret;

	enable_irq_wake(s->open_irq);
	enable_irq_wake(s->close_irq);
	dev_info(dev, "%s: type %u code %u\n", label, s->type, s->code);
	return 0;
}

static int xiaomi_hall_probe(struct platform_device *pdev)
{
	struct device_node *child;
	int ret, n = 0;

	for_each_available_child_of_node(pdev->dev.of_node, child) {
		ret = xiaomi_hall_add(&pdev->dev, child);
		if (ret) {
			of_node_put(child);
			return ret;
		}
		n++;
	}
	return n ? 0 : -ENODEV;
}

static const struct of_device_id xiaomi_hall_of_match[] = {
	{ .compatible = "xiaomi-hall" },
	{ }
};
MODULE_DEVICE_TABLE(of, xiaomi_hall_of_match);

static struct platform_driver xiaomi_hall_driver = {
	.probe = xiaomi_hall_probe,
	.driver = {
		.name = "xiaomi-hall",
		.of_match_table = xiaomi_hall_of_match,
	},
};
module_platform_driver(xiaomi_hall_driver);

MODULE_DESCRIPTION("Xiaomi lid hall sensor");
MODULE_LICENSE("GPL");
