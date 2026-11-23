# SPDX-License-Identifier: GPL-2.0-only
#
# Makefile for Code Aurora Forum (CAF) Qualcomm platform drivers
#

# Core CAF platform
obj-$(CONFIG_ARCH_QCOM_CAF) += caf-core.o

# CAF Audio
obj-$(CONFIG_SND_SOC_QCOM) += audio/
obj-$(CONFIG_SND_SOC_QCOM_ADSP) += audio/
obj-$(CONFIG_SND_SOC_QCOM_WCD) += audio/
obj-$(CONFIG_SND_SOC_QDSP6) += audio/

# CAF Camera
obj-$(CONFIG_CAMSS_QCOM) += camera/
obj-$(CONFIG_QCOM_CAMSS) += camera/
obj-$(CONFIG_QCOM_CAMERA_SENSOR) += camera/

# CAF Display
obj-$(CONFIG_MSM_DISPLAY) += display/
obj-$(CONFIG_DRM_MSM) += display/
obj-$(CONFIG_DRM_MSM_DPU) += display/
obj-$(CONFIG_DRM_MSM_HDMI) += display/

# CAF Power Management
obj-$(CONFIG_QCOM_SPMI_PMIC) += power/
obj-$(CONFIG_QCOM_SPMI_ADSP) += power/
obj-$(CONFIG_QCOM_SPMI_PMIC_ARB) += power/
obj-$(CONFIG_QCOM_SPMI_WRAPPER) += power/
obj-$(CONFIG_QCOM_PDC) += power/
obj-$(CONFIG_QCOM_RPMH) += power/
obj-$(CONFIG_QCOM_RPMH_ADSP) += power/
obj-$(CONFIG_QCOM_RPMT) += power/
obj-$(CONFIG_QCOM_RPMH_VS) += power/
obj-$(CONFIG_QCOM_CPR) += power/
obj-$(CONFIG_QCOM_LLCC) += power/
obj-$(CONFIG_QCOM_POWER) += power/
obj-$(CONFIG_QCOM_WATCHDOG) += power/

# CAF Interconnect
obj-$(CONFIG_QCOM_ICC_QCOM) += connectivity/
obj-$(CONFIG_QCOM_ICC_RPMH) += connectivity/

# CAF Clock Control
obj-$(CONFIG_QCOM_CLOCK_OMNI_POCR) += power/
obj-$(CONFIG_QCOM_CLOCK_RPMH_CXO) += power/
obj-$(CONFIG_QCOM_CLOCK_VIBRATOR) += power/

# CAF GPIO and Pin Control
obj-$(CONFIG_PINCTRL_QCOM) += connectivity/
obj-$(CONFIG_GPIO_QCOM) += connectivity/

# CAF Connectivity
obj-$(CONFIG_QCOM_QUPV3_I2C) += connectivity/
obj-$(CONFIG_QCOM_USB_HSIC_PHY) += connectivity/
obj-$(CONFIG_QCOM_USB_HS_PHY) += connectivity/
obj-$(CONFIG_QCOM_USB_SS_PHY) += connectivity/

# CAF Shared Memory and IPC
obj-$(CONFIG_QCOM_SMEM) += power/
obj-$(CONFIG_QCOM_SMEM_STATE) += power/
obj-$(CONFIG_QCOM_SMEM_SDP) += power/
obj-$(CONFIG_QCOM_SMD_RPM) += power/
obj-$(CONFIG_QCOM_RMTFS_MEM) += power/
obj-$(CONFIG_QCOM_GENI_SE) += power/
obj-$(CONFIG_QCOM_GENI_SMEM_IPC) += power/

ccflags-$(CONFIG_CAF_DEBUG) += -DCAF_DEBUG
