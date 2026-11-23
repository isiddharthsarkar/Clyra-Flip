/*
 * susfs - SU Filesystem for KernelSU
 *
 * Copyright (C) 2022-2024 KernelSU Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef _SUSFS_H
#define _SUSFS_H

#include <linux/fs.h>
#include <linux/mount.h>

/* susfs superblock magic */
#define SUSFS_MAGIC 0x53554653 /* "SUFS" */

/* susfs file types */
#define SUSFS_FILE_ROOT       "root"
#define SUSFS_FILE_UNROOT     "unroot"
#define SUSFS_FILE_IS_ROOT    "is_root"
#define SUSFS_FILE_HIDE       "hide"
#define SUSFS_FILE_UNHIDE     "unhide"
#define SUSFS_FILE_VERSION    "version"

/* External functions */
int ksu_susfs_register(void);
void ksu_susfs_unregister(void);

#endif /* _SUSFS_H */
