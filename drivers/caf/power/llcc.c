/*
 * CAF QCOM llcc driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "llcc: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM llcc driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init llcc_init(void)
{
	pr_info("CAF QCOM llcc initializing\n");
	return 0;
}

static void __exit llcc_exit(void)
{
	pr_info("CAF QCOM llcc exiting\n");
}

module_init(llcc_init);
module_exit(llcc_exit);
