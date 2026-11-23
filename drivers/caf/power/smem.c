/*
 * CAF QCOM smem driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "smem: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM Shared Memory (SMEM) driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init smem_init(void)
{
	pr_info("CAF QCOM smem initializing\n");
	return 0;
}

static void __exit smem_exit(void)
{
	pr_info("CAF QCOM smem exiting\n");
}

module_init(smem_init);
module_exit(smem_exit);
