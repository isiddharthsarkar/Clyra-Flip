/*
 * CAF QCOM rmtfs-mem driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "rmtfs-mem: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM Remote Filesystem memory driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init rmtfs_mem_init(void)
{
	pr_info("CAF QCOM rmtfs-mem initializing\n");
	return 0;
}

static void __exit rmtfs_mem_exit(void)
{
	pr_info("CAF QCOM rmtfs-mem exiting\n");
}

module_init(rmtfs_mem_init);
module_exit(rmtfs_mem_exit);
