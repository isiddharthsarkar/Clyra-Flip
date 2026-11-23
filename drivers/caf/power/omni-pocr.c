/*
 * CAF QCOM omni-pocr driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "omni-pocr: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM omni-pocr driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init omni_pocr_init(void)
{
	pr_info("CAF QCOM omni-pocr initializing\n");
	return 0;
}

static void __exit omni_pocr_exit(void)
{
	pr_info("CAF QCOM omni-pocr exiting\n");
}

module_init(omni_pocr_init);
module_exit(omni_pocr_exit);
