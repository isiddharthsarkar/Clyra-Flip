/*
 * susfs - SU Filesystem for KernelSU
 *
 * Copyright (C) 2022-2024 KernelSU Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "susfs: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/pagemap.h>
#include <linux/mount.h>
#include <linux/namei.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/seq_file.h>

#include "ksu.h"
#include "susfs.h"

MODULE_AUTHOR("KernelSU Contributors");
MODULE_DESCRIPTION("susfs - SU Filesystem for KernelSU");
MODULE_LICENSE("GPL v2");

/* ------------------------------------------------------------------------
 * susfs inode operations
 * ------------------------------------------------------------------------ */

static int susfs_fill_super(struct super_block *sb, void *data, int silent)
{
	struct inode *root_inode;

	sb->s_magic = SUSFS_MAGIC;
	sb->s_maxbytes = MAX_LFS_FILESIZE;
	sb->s_time_gran = 1;

	root_inode = new_inode(sb);
	if (!root_inode)
		return -ENOMEM;

	root_inode->i_ino = 1;
	root_inode->i_mode = S_IFDIR | 0755;
	root_inode->i_uid = GLOBAL_ROOT_UID;
	root_inode->i_gid = GLOBAL_ROOT_GID;
	root_inode->i_atime = root_inode->i_mtime = root_inode->i_ctime =
		current_time(root_inode);
	root_inode->i_op = &simple_dir_inode_operations;
	root_inode->i_fop = &simple_dir_operations;

	sb->s_root = d_make_root(root_inode);
	if (!sb->s_root) {
		iput(root_inode);
		return -ENOMEM;
	}

	return 0;
}

static struct dentry *susfs_mount(struct file_system_type *fs_type,
				  int flags, const char *dev_name, void *data)
{
	return mount_nodev(fs_type, flags, data, susfs_fill_super);
}

static struct file_system_type susfs_fs_type = {
	.owner = THIS_MODULE,
	.name = "susfs",
	.mount = susfs_mount,
	.kill_sb = kill_anon_super,
};

/* ------------------------------------------------------------------------
 * susfs control file operations (write-only control files)
 * ------------------------------------------------------------------------ */

static ssize_t susfs_control_write(struct file *file, const char __user *buf,
				   size_t count, loff_t *ppos)
{
	struct inode *inode = file_inode(file);
	char *name = inode->i_private;
	int ret = 0;

	if (count == 0 || count > 64)
		return -EINVAL;

	if (!ksu_gs.enabled)
		return -EPERM;

	if (strcmp(name, SUSFS_FILE_ROOT) == 0) {
		ret = ksu_grant_root(current);
		if (ret == 0) {
			pr_info("susfs: granted root via %s\n", name);
			ret = count;
		}
	} else if (strcmp(name, SUSFS_FILE_UNROOT) == 0) {
		ret = ksu_revoke_root(current);
		if (ret == 0) {
			pr_info("susfs: revoked root via %s\n", name);
			ret = count;
		}
	} else if (strcmp(name, SUSFS_FILE_HIDE) == 0) {
		ksu_hide_enable();
		ret = count;
	} else if (strcmp(name, SUSFS_FILE_UNHIDE) == 0) {
		ksu_hide_disable();
		ret = count;
	} else {
		ret = -EINVAL;
	}

	return ret;
}

static ssize_t susfs_status_read(struct file *file, char __user *buf,
				 size_t count, loff_t *ppos)
{
	char status[256];
	int len;

	len = snprintf(status, sizeof(status),
		       "enabled=%d\nhide_root=%d\nversion=%s\n",
		       ksu_gs.enabled, ksu_gs.hide_root, KSU_VERSION);

	if (*ppos >= len)
		return 0;

	if (count > len - *ppos)
		count = len - *ppos;

	if (copy_to_user(buf, status + *ppos, count))
		return -EFAULT;

	*ppos += count;
	return count;
}

static const struct file_operations susfs_control_fops = {
	.write = susfs_control_write,
	.owner = THIS_MODULE,
};

static const struct file_operations susfs_status_fops = {
	.read = susfs_status_read,
	.owner = THIS_MODULE,
};

/* ------------------------------------------------------------------------
 * susfs directory population
 * ------------------------------------------------------------------------ */

static int susfs_create_files(struct super_block *sb,
			      struct dentry *root)
{
	struct dentry *dentry;
	struct inode *inode;
	const char *files[] = {
		SUSFS_FILE_ROOT,
		SUSFS_FILE_UNROOT,
		SUSFS_FILE_IS_ROOT,
		SUSFS_FILE_HIDE,
		SUSFS_FILE_UNHIDE,
		SUSFS_FILE_VERSION,
		NULL
	};
	int i;

	for (i = 0; files[i] != NULL; i++) {
		dentry = d_alloc_name(root, files[i]);
		if (!dentry)
			continue;

		inode = new_inode(sb);
		if (!inode) {
			dput(dentry);
			continue;
		}

		inode->i_ino = d_inode(dentry) ? d_inode(dentry)->i_ino : (i + 2);
		inode->i_uid = GLOBAL_ROOT_UID;
		inode->i_gid = GLOBAL_ROOT_GID;
		inode->i_atime = inode->i_mtime = inode->i_ctime =
			current_time(inode);

		if (strcmp(files[i], SUSFS_FILE_IS_ROOT) == 0 ||
		    strcmp(files[i], SUSFS_FILE_VERSION) == 0) {
			/* Read-only status files */
			inode->i_mode = S_IFREG | 0444;
			inode->i_fop = &susfs_status_fops;
		} else {
			/* Write-only control files */
			inode->i_mode = S_IFREG | 0222;
			inode->i_fop = &susfs_control_fops;
			inode->i_private = (void *)files[i];
		}

		d_add(dentry, inode);
	}

	return 0;
}

/* ------------------------------------------------------------------------
 * Module init / exit
 * ------------------------------------------------------------------------ */

int ksu_susfs_register(void)
{
	int ret;

	ret = register_filesystem(&susfs_fs_type);
	if (ret < 0) {
		pr_err("failed to register susfs filesystem\n");
		return ret;
	}

	pr_info("susfs filesystem registered\n");
	return 0;
}
EXPORT_SYMBOL_GPL(ksu_susfs_register);

void ksu_susfs_unregister(void)
{
	unregister_filesystem(&susfs_fs_type);
	pr_info("susfs filesystem unregistered\n");
}
EXPORT_SYMBOL_GPL(ksu_susfs_unregister);

static int __init susfs_init(void)
{
	/* susfs is registered via ksu_susfs_register() called from ksu.c */
	return 0;
}

static void __exit susfs_exit(void)
{
	/* Nothing to do - unregistration handled by ksu.c */
}

module_init(susfs_init);
module_exit(susfs_exit);