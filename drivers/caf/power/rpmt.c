/*
 * CAF QCOM rpmt driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "rpmt: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM rpmt driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init rpmt_init(void)
{
	pr_info("CAF QCOM rpmt initializing\n");
	return 0;
}

static void __exit rpmt_exit(void)
{
	pr_info("CAF QCOM rpmt exiting\n");
}

module_init(rpmt_init);
module_exit(rpmt_exit);
