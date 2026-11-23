/*
 * CAF QCOM icc-rpmh driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "icc-rpmh: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM icc-rpmh driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init icc_rpmh_init(void)
{
	pr_info("CAF QCOM icc-rpmh initializing\n");
	return 0;
}

static void __exit icc_rpmh_exit(void)
{
	pr_info("CAF QCOM icc-rpmh exiting\n");
}

module_init(icc_rpmh_init);
module_exit(icc_rpmh_exit);
