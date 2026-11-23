/*
 * CAF QCOM smem-sdp driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "smem-sdp: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM SMEM SDP driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init smem_sdp_init(void)
{
	pr_info("CAF QCOM smem-sdp initializing\n");
	return 0;
}

static void __exit smem_sdp_exit(void)
{
	pr_info("CAF QCOM smem-sdp exiting\n");
}

module_init(smem_sdp_init);
module_exit(smem_sdp_exit);
