/*
 * CAF DRM MSM HDMI driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "msm-hdmi: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF DRM MSM HDMI driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init msm_hdmi_init(void)
{
	pr_info("CAF DRM MSM HDMI initializing\n");
	return 0;
}

static void __exit msm_hdmi_exit(void)
{
	pr_info("CAF DRM MSM HDMI exiting\n");
}

module_init(msm_hdmi_init);
module_exit(msm_hdmi_exit);
