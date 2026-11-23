/*
 * CAF DRM MSM display driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "msm-drm: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <drm/drm_device.h>
#include <drm/drm_drv.h>
#include <drm/drm_crtc.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF DRM MSM display driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init msm_drm_init(void)
{
	pr_info("CAF DRM MSM display driver initializing\n");
	return 0;
}

static void __exit msm_drm_exit(void)
{
	pr_info("CAF DRM MSM display driver exiting\n");
}

module_init(msm_drm_init);
module_exit(msm_drm_exit);