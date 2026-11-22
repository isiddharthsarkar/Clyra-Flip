/*
 * CAF QCOM usb-ss-phy driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "usb-ss-phy: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM usb-ss-phy driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init usb-ss-phy_init(void)
{
	pr_info("CAF QCOM usb-ss-phy initializing\n");
	return 0;
}

static void __exit usb-ss-phy_exit(void)
{
	pr_info("CAF QCOM usb-ss-phy exiting\n");
}

module_init(usb-ss-phy_init);
module_exit(usb-ss-phy_exit);
