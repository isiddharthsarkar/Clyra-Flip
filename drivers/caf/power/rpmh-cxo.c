/*
 * CAF QCOM rpmh-cxo driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "rpmh-cxo: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM rpmh-cxo driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init rpmh_cxo_init(void)
{
	pr_info("CAF QCOM rpmh-cxo initializing\n");
	return 0;
}

static void __exit rpmh_cxo_exit(void)
{
	pr_info("CAF QCOM rpmh-cxo exiting\n");
}

module_init(rpmh_cxo_init);
module_exit(rpmh_cxo_exit);
