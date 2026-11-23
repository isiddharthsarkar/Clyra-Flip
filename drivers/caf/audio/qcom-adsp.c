/*
 * CAF QDSP6 ADSP audio processor driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "qcom-adsp: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QDSP6 ADSP audio processor driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init qcom_adsp_init(void)
{
	pr_info("CAF QDSP6 ADSP audio processor initializing\n");
	return 0;
}

static void __exit qcom_adsp_exit(void)
{
	pr_info("CAF QDSP6 ADSP audio processor exiting\n");
}

module_init(qcom_adsp_init);
module_exit(qcom_adsp_exit);