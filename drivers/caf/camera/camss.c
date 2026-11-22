/*
 * CAF QCOM Camera Subsystem core driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "camss: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <media/v4l2-device.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM Camera Subsystem core driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init camss_init(void)
{
	pr_info("CAF QCOM Camera Subsystem initializing\n");
	return 0;
}

static void __exit camss_exit(void)
{
	pr_info("CAF QCOM Camera Subsystem exiting\n");
}

module_init(camss_init);
module_exit(camss_exit);