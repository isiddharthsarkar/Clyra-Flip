/*
 * CAF Qualcomm SoC Audio core driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "qcom-audio: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF Qualcomm SoC Audio core driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init qcom_audio_init(void)
{
	pr_info("CAF Qualcomm SoC Audio core initializing\n");
	return 0;
}

static void __exit qcom_audio_exit(void)
{
	pr_info("CAF Qualcomm SoC Audio core exiting\n");
}

module_init(qcom_audio_init);
module_exit(qcom_audio_exit);