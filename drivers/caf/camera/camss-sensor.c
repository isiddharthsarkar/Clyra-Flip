/*
 * CAF QCOM camera sensor driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "camss-sensor: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <media/v4l2-subdev.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM camera sensor driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init camss_sensor_init(void)
{
	pr_info("CAF QCOM camera sensor initializing\n");
	return 0;
}

static void __exit camss_sensor_exit(void)
{
	pr_info("CAF QCOM camera sensor exiting\n");
}

module_init(camss_sensor_init);
module_exit(camss_sensor_exit);