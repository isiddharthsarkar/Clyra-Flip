/*
 * CAF QCOM spmi-pmic driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "spmi-pmic: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM spmi-pmic driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init spmi-pmic_init(void)
{
	pr_info("CAF QCOM spmi-pmic initializing\n");
	return 0;
}

static void __exit spmi-pmic_exit(void)
{
	pr_info("CAF QCOM spmi-pmic exiting\n");
}

module_init(spmi-pmic_init);
module_exit(spmi-pmic_exit);
