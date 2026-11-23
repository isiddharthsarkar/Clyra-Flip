/*
 * CAF (Code Aurora Forum) Qualcomm platform core driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "caf-core: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/string.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF Qualcomm platform core driver for SM7435");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

/* CAF platform data */
struct caf_platform_data {
	bool smem_initialized;
	bool spmi_initialized;
	bool rpmh_initialized;
	bool pinctrl_initialized;
	bool gpio_initialized;
};

static struct caf_platform_data caf_pd;

/* CAF platform init */
static int __init caf_platform_init(void)
{
	pr_info("CAF Qualcomm platform core initializing (SM7435/parrot)\n");

	memset(&caf_pd, 0, sizeof(caf_pd));

	/* Mark subsystems as initialized - actual init done by individual drivers */
	caf_pd.smem_initialized = true;
	caf_pd.spmi_initialized = true;
	caf_pd.rpmh_initialized = true;
	caf_pd.pinctrl_initialized = true;
	caf_pd.gpio_initialized = true;

	pr_info("CAF Qualcomm platform core initialized\n");
	return 0;
}

static void __exit caf_platform_exit(void)
{
	pr_info("CAF Qualcomm platform core exiting\n");
	memset(&caf_pd, 0, sizeof(caf_pd));
}

module_init(caf_platform_init);
module_exit(caf_platform_exit);
