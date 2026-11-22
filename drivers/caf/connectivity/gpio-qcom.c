/*
 * CAF QCOM gpio-qcom driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "gpio-qcom: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM gpio-qcom driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init gpio-qcom_init(void)
{
	pr_info("CAF QCOM gpio-qcom initializing\n");
	return 0;
}

static void __exit gpio-qcom_exit(void)
{
	pr_info("CAF QCOM gpio-qcom exiting\n");
}

module_init(gpio-qcom_init);
module_exit(gpio-qcom_exit);
