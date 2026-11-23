/*
 * KernelSU - Kernel-level root solution for Android
 *
 * Copyright (C) 2022-2024 KernelSU Contributors
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef _KSU_H
#define _KSU_H

#include <linux/cred.h>
#include <linux/sched.h>
#include <linux/pid.h>
#include <linux/list.h>
#include <linux/mutex.h>
#include <linux/fs.h>
#include <linux/device.h>

/* KernelSU Next / KowSU version */
#define KSU_VERSION "1.0.5-next"
#define KSU_VERSION_CODE 10505
#define KOWSU_VERSION "1.0.5-kowsu"

/* Version flags reported to manager APKs */
#define KSU_FLAG_NEXT             0x00000001
#define KSU_FLAG_KOWSU            0x00000002
#define KSU_FLAG_SUSFS            0x00000004
#define KSU_FLAG_SELINUX_ENFORCE  0x00000008

/* Maximum number of root-enabled processes tracked */
#define KSU_MAX_PROCS 4096

/* Version info payload for manager apps */
struct ksu_version_info {
	__u32 version;
	__u32 flags;
	__u32 manager_uid;
};

/* KSU / KSUN / KowSU ioctl commands */
#define KSU_IOC_MAGIC 'k'
#define KSU_IOC_ROOT            _IOW(KSU_IOC_MAGIC, 1, int)
#define KSU_IOC_UNROOT          _IOW(KSU_IOC_MAGIC, 2, int)
#define KSU_IOC_IS_ROOT         _IOR(KSU_IOC_MAGIC, 3, int)
#define KSU_IOC_HIDE            _IOW(KSU_IOC_MAGIC, 4, int)
#define KSU_IOC_UNHIDE          _IOW(KSU_IOC_MAGIC, 5, int)
#define KSU_IOC_VERSION         _IOR(KSU_IOC_MAGIC, 6, char[32])
#define KSU_IOC_GET_INFO        _IOR(KSU_IOC_MAGIC, 7, struct ksu_version_info)
#define KSU_IOC_GRANT_ROOT      _IOW(KSU_IOC_MAGIC, 8, int)
#define KSU_IOC_REPORT_EVENT    _IOW(KSU_IOC_MAGIC, 9, unsigned long)
#define KSU_IOC_SET_SEPOLICY    _IOW(KSU_IOC_MAGIC, 10, unsigned long)
#define KSU_IOC_CHECK_SAFEMODE  _IOR(KSU_IOC_MAGIC, 11, int)
#define KSU_IOC_GET_ALLOW_LIST  _IOWR(KSU_IOC_MAGIC, 12, unsigned long)

/* Process root state */
enum ksu_proc_state {
	KSU_PROC_UNROOTED = 0,
	KSU_PROC_ROOTED = 1,
	KSU_PROC_DENIED = 2,
};

/* Tracked process entry */
struct ksu_proc_entry {
	struct list_head list;
	pid_t pid;
	enum ksu_proc_state state;
	kuid_t uid;
	kgid_t gid;
	unsigned long flags;
};

/* KSU global state */
struct ksu_state {
	bool enabled;
	bool hide_root;
	bool debug;
	bool log_ops;
	struct mutex lock;
	struct list_head procs;
	int proc_count;
};

/* External state reference */
extern struct ksu_state ksu_gs;

/* Core functions */
int __init ksu_init(void);
void __exit ksu_exit(void);
int ksu_grant_root(struct task_struct *task);
int ksu_revoke_root(struct task_struct *task);
int ksu_check_root(struct task_struct *task);
void ksu_hide_enable(void);
void ksu_hide_disable(void);
int ksu_get_version(char *buf, size_t size);

/* susfs interface */
int ksu_susfs_register(void);
void ksu_susfs_unregister(void);

#endif /* _KSU_H */
