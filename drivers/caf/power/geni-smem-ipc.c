/*
 * CAF QCOM geni-smem-ipc driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "geni-smem-ipc: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM GENI SMEM IPC driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("1.0.0");

static int __init geni_smem_ipc_init(void)
{
	pr_info("CAF QCOM geni-smem-ipc initializing\n");
	return 0;
}

static void __exit geni_smem_ipc_exit(void)
{
	pr_info("CAF QCOM geni-smem-ipc exiting\n");
}

module_init(geni_smem_ipc_init);
module_exit(geni_smem_ipc_exit);
