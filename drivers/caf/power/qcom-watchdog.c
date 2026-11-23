/*
 * CAF QCOM qcom-watchdog driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "qcom-watchdog: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM qcom-watchdog driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init qcom_watchdog_init(void)
{
	pr_info("CAF QCOM qcom-watchdog initializing\n");
	return 0;
}

static void __exit qcom_watchdog_exit(void)
{
	pr_info("CAF QCOM qcom-watchdog exiting\n");
}

module_init(qcom_watchdog_init);
module_exit(qcom_watchdog_exit);
