# SPDX-License-Identifier: GPL-2.0-only
#
# Makefile for KernelSU
#

obj-$(CONFIG_KERNEL_SU) += ksu.o
obj-$(CONFIG_KERNEL_SU) += susfs/susfs.o

ksu-y := ksu.o

susfs-y := susfs.o

ccflags-$(CONFIG_KSU_DEBUG) += -DKSU_DEBUG