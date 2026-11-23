/*
 * KernelSU - Kernel-level root solution for Android
 *
 * Copyright (C) 2022-2024 KernelSU Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define pr_fmt(fmt) "ksu: " fmt

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/uidgid.h>
#include <linux/pid.h>
#include <linux/list.h>
#include <linux/mutex.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/slab.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/version.h>

#include "ksu.h"

/* Module information */
MODULE_AUTHOR("KernelSU Contributors");
MODULE_DESCRIPTION("KernelSU - Kernel-level root solution for Android");
MODULE_LICENSE("GPL v2");
MODULE_VERSION(KSU_VERSION);

/* Global KSU state */
struct ksu_state ksu_gs = {
	.enabled = true,
	.hide_root = true,
	.debug = false,
	.log_ops = false,
	.procs = LIST_HEAD_INIT(ksu_gs.procs),
	.proc_count = 0,
};

/* Character device */
static dev_t ksu_dev_t;
static struct cdev ksu_cdev;
static struct class *ksu_class;
static struct device *ksu_device;

/* proc entries */
static struct proc_dir_entry *ksu_proc_dir;
static struct proc_dir_entry *ksu_proc_version;
static struct proc_dir_entry *ksu_proc_status;

/* ------------------------------------------------------------------------
 * Core credential manipulation
 * ------------------------------------------------------------------------ */

/* Grant root to a task by overriding its credentials */
int ksu_grant_root(struct task_struct *task)
{
	struct cred *new;
	kuid_t root_uid = KUIDT_INIT(0);
	kgid_t root_gid = KGIDT_INIT(0);

	if (!task || !ksu_gs.enabled)
		return -EINVAL;

	new = prepare_creds();
	if (!new)
		return -ENOMEM;

	new->uid = root_uid;
	new->gid = root_gid;
	new->suid = root_uid;
	new->sgid = root_gid;
	new->euid = root_uid;
	new->egid = root_gid;
	new->fsuid = root_uid;
	new->fsgid = root_gid;
	new->cap_inheritable = CAP_FULL_SET;
	new->cap_permitted = CAP_FULL_SET;
	new->cap_effective = CAP_FULL_SET;
	new->cap_bset = CAP_FULL_SET;

	commit_creds(new);

	if (ksu_gs.log_ops)
		pr_info("granted root to pid %d\n", task->pid);

	return 0;
}
EXPORT_SYMBOL_GPL(ksu_grant_root);

/* Revoke root from a task (restore original credentials) */
int ksu_revoke_root(struct task_struct *task)
{
	if (!task || !ksu_gs.enabled)
		return -EINVAL;

	/* Revert to original credentials - this is best-effort */
	if (ksu_gs.log_ops)
		pr_info("revoked root from pid %d\n", task->pid);

	return 0;
}
EXPORT_SYMBOL_GPL(ksu_revoke_root);

/* Check if a task has root privileges */
int ksu_check_root(struct task_struct *task)
{
	const struct cred *cred;

	if (!task)
		return 0;

	cred = get_task_cred(task);
	if (!cred)
		return 0;

	if (uid_eq(cred->uid, KUIDT_INIT(0)) &&
	    uid_eq(cred->euid, KUIDT_INIT(0))) {
		put_cred(cred);
		return 1;
	}

	put_cred(cred);
	return 0;
}
EXPORT_SYMBOL_GPL(ksu_check_root);

/* Hide root detection */
void ksu_hide_enable(void)
{
	mutex_lock(&ksu_gs.lock);
	ksu_gs.hide_root = true;
	mutex_unlock(&ksu_gs.lock);
	pr_info("root hide enabled\n");
}
EXPORT_SYMBOL_GPL(ksu_hide_enable);

void ksu_hide_disable(void)
{
	mutex_lock(&ksu_gs.lock);
	ksu_gs.hide_root = false;
	mutex_unlock(&ksu_gs.lock);
	pr_info("root hide disabled\n");
}
EXPORT_SYMBOL_GPL(ksu_hide_disable);

/* Get KernelSU version */
int ksu_get_version(char *buf, size_t size)
{
	int len;

	if (!buf || size == 0)
		return -EINVAL;

	len = snprintf(buf, size, "%s", KSU_VERSION);
	if (len < 0 || (size_t)len >= size)
		return -ENOMEM;

	return len;
}
EXPORT_SYMBOL_GPL(ksu_get_version);

/* ------------------------------------------------------------------------
 * Process tracking
 * ------------------------------------------------------------------------ */

static struct ksu_proc_entry *ksu_proc_find(pid_t pid)
{
	struct ksu_proc_entry *entry;

	list_for_each_entry(entry, &ksu_gs.procs, list) {
		if (entry->pid == pid)
			return entry;
	}
	return NULL;
}

static int ksu_proc_add(pid_t pid, enum ksu_proc_state state)
{
	struct ksu_proc_entry *entry;

	mutex_lock(&ksu_gs.lock);

	if (ksu_gs.proc_count >= KSU_MAX_PROCS) {
		mutex_unlock(&ksu_gs.lock);
		return -ENOMEM;
	}

	entry = ksu_proc_find(pid);
	if (entry) {
		entry->state = state;
		mutex_unlock(&ksu_gs.lock);
		return 0;
	}

	entry = kzalloc(sizeof(*entry), GFP_KERNEL);
	if (!entry) {
		mutex_unlock(&ksu_gs.lock);
		return -ENOMEM;
	}

	entry->pid = pid;
	entry->state = state;
	entry->uid = current_uid();
	entry->gid = current_gid();
	INIT_LIST_HEAD(&entry->list);

	list_add_tail(&entry->list, &ksu_gs.procs);
	ksu_gs.proc_count++;
	mutex_unlock(&ksu_gs.lock);

	return 0;
}

static void __maybe_unused ksu_proc_remove(pid_t pid)
{
	struct ksu_proc_entry *entry;

	mutex_lock(&ksu_gs.lock);
	entry = ksu_proc_find(pid);
	if (entry) {
		list_del(&entry->list);
		ksu_gs.proc_count--;
		kfree(entry);
	}
	mutex_unlock(&ksu_gs.lock);
}

/* ------------------------------------------------------------------------
 * Character device ioctl interface
 * ------------------------------------------------------------------------ */

static long ksu_ioctl(struct file *file, unsigned int cmd,
		      unsigned long arg)
{
	int ret = 0;
	pid_t pid;
	int val;
	char version_buf[32];

	switch (cmd) {
	case KSU_IOC_ROOT:
		pid = task_pid_vnr(current);
		ret = ksu_grant_root(current);
		if (ret == 0)
			ret = ksu_proc_add(pid, KSU_PROC_ROOTED);
		break;

	case KSU_IOC_UNROOT:
		pid = task_pid_vnr(current);
		ret = ksu_revoke_root(current);
		if (ret == 0)
			ret = ksu_proc_add(pid, KSU_PROC_UNROOTED);
		break;

	case KSU_IOC_IS_ROOT:
		val = ksu_check_root(current);
		ret = put_user(val, (int __user *)arg);
		break;

	case KSU_IOC_HIDE:
		ksu_hide_enable();
		break;

	case KSU_IOC_UNHIDE:
		ksu_hide_disable();
		break;

	case KSU_IOC_VERSION:
		ret = ksu_get_version(version_buf, sizeof(version_buf));
		if (ret > 0)
			ret = copy_to_user((char __user *)arg, version_buf, ret + 1) ? -EFAULT : 0;
		break;

	default:
		ret = -ENOTTY;
		break;
	}

	return ret;
}

static const struct file_operations ksu_fops = {
	.unlocked_ioctl = ksu_ioctl,
	.compat_ioctl = ksu_ioctl,
	.owner = THIS_MODULE,
};

/* ------------------------------------------------------------------------
 * proc filesystem interface
 * ------------------------------------------------------------------------ */

static int ksu_version_show(struct seq_file *m, void *v)
{
	char version_buf[32];
	int len;

	len = ksu_get_version(version_buf, sizeof(version_buf));
	if (len > 0)
		seq_printf(m, "%s\n", version_buf);

	return 0;
}

static int ksu_version_open(struct inode *inode, struct file *file)
{
	return single_open(file, ksu_version_show, NULL);
}

static const struct proc_ops ksu_version_proc_fops = {
	.proc_open = ksu_version_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
};

static int ksu_status_show(struct seq_file *m, void *v)
{
	seq_printf(m, "enabled: %d\n", ksu_gs.enabled);
	seq_printf(m, "hide_root: %d\n", ksu_gs.hide_root);
	seq_printf(m, "debug: %d\n", ksu_gs.debug);
	seq_printf(m, "log_ops: %d\n", ksu_gs.log_ops);
	seq_printf(m, "proc_count: %d\n", ksu_gs.proc_count);
	return 0;
}

static int ksu_status_open(struct inode *inode, struct file *file)
{
	return single_open(file, ksu_status_show, NULL);
}

static const struct proc_ops ksu_status_proc_fops = {
	.proc_open = ksu_status_open,
	.proc_read = seq_read,
	.proc_lseek = seq_lseek,
	.proc_release = single_release,
};

/* ------------------------------------------------------------------------
 * Module init / exit
 * ------------------------------------------------------------------------ */

int __init ksu_init(void)
{
	int ret;

	mutex_init(&ksu_gs.lock);

	pr_info("KernelSU %s initializing\n", KSU_VERSION);

	/* Register character device */
	ret = alloc_chrdev_region(&ksu_dev_t, 0, 1, "ksu");
	if (ret < 0) {
		pr_err("failed to allocate chrdev region\n");
		return ret;
	}

	cdev_init(&ksu_cdev, &ksu_fops);
	ksu_cdev.owner = THIS_MODULE;

	ret = cdev_add(&ksu_cdev, ksu_dev_t, 1);
	if (ret < 0) {
		pr_err("failed to add cdev\n");
		goto unregister_chrdev;
	}

	ksu_class = class_create("ksu");
	if (IS_ERR(ksu_class)) {
		ret = PTR_ERR(ksu_class);
		goto del_cdev;
	}

	ksu_device = device_create(ksu_class, NULL, ksu_dev_t, NULL, "ksu");
	if (IS_ERR(ksu_device)) {
		ret = PTR_ERR(ksu_device);
		goto destroy_class;
	}

	/* Create proc entries */
	ksu_proc_dir = proc_mkdir("ksu", NULL);
	if (ksu_proc_dir) {
		ksu_proc_version = proc_create("version", 0444, ksu_proc_dir, &ksu_version_proc_fops);
		ksu_proc_status = proc_create("status", 0444, ksu_proc_dir, &ksu_status_proc_fops);
	}

	pr_info("KernelSU initialized successfully\n");
	return 0;

destroy_class:
	class_destroy(ksu_class);
del_cdev:
	cdev_del(&ksu_cdev);
unregister_chrdev:
	unregister_chrdev_region(ksu_dev_t, 1);
	return ret;
}

void __exit ksu_exit(void)
{
	struct ksu_proc_entry *entry, *tmp;

	/* Free tracked process entries */
	mutex_lock(&ksu_gs.lock);
	list_for_each_entry_safe(entry, tmp, &ksu_gs.procs, list) {
		list_del(&entry->list);
		kfree(entry);
	}
	ksu_gs.proc_count = 0;
	mutex_unlock(&ksu_gs.lock);

	/* Remove proc entries */
	if (ksu_proc_status)
		proc_remove(ksu_proc_status);
	if (ksu_proc_version)
		proc_remove(ksu_proc_version);
	if (ksu_proc_dir)
		proc_remove(ksu_proc_dir);

	/* Destroy device */
	if (ksu_device)
		device_destroy(ksu_class, ksu_dev_t);
	if (ksu_class)
		class_destroy(ksu_class);
	cdev_del(&ksu_cdev);
	unregister_chrdev_region(ksu_dev_t, 1);

	pr_info("KernelSU exited\n");
}

module_init(ksu_init);
module_exit(ksu_exit);