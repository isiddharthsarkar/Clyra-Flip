/*
 * CAF QCOM smd-rpm driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "smd-rpm: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM SMD RPM doorbell driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init smd_rpm_init(void)
{
	pr_info("CAF QCOM smd-rpm initializing\n");
	return 0;
}

static void __exit smd_rpm_exit(void)
{
	pr_info("CAF QCOM smd-rpm exiting\n");
}

module_init(smd_rpm_init);
module_exit(smd_rpm_exit);
