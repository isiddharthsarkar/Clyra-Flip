/*
 * CAF QCOM geni-se driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "geni-se: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM GENI Security Engine driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init geni_se_init(void)
{
	pr_info("CAF QCOM geni-se initializing\n");
	return 0;
}

static void __exit geni_se_exit(void)
{
	pr_info("CAF QCOM geni-se exiting\n");
}

module_init(geni_se_init);
module_exit(geni_se_exit);
