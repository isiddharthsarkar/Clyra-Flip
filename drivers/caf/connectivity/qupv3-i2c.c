/*
 * CAF QCOM qupv3-i2c driver
 *
 * Copyright (C) 2024 Clyra-Flip Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "qupv3-i2c: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

MODULE_AUTHOR("Clyra-Flip Contributors");
MODULE_DESCRIPTION("CAF QCOM qupv3-i2c driver");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("6.6.162");

static int __init qupv3_i2c_init(void)
{
	pr_info("CAF QCOM qupv3-i2c initializing\n");
	return 0;
}

static void __exit qupv3_i2c_exit(void)
{
	pr_info("CAF QCOM qupv3-i2c exiting\n");
}

module_init(qupv3_i2c_init);
module_exit(qupv3_i2c_exit);
