/*
 * CAF QCOM rpmh-adsp driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "rpmh-adsp: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM rpmh-adsp driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init rpmh_adsp_init(void)
{
	pr_info("CAF QCOM rpmh-adsp initializing\n");
	return 0;
}

static void __exit rpmh_adsp_exit(void)
{
	pr_info("CAF QCOM rpmh-adsp exiting\n");
}

module_init(rpmh_adsp_init);
module_exit(rpmh_adsp_exit);
