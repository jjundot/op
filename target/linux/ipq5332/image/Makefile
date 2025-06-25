define Device/jd-be6500
  $(Device/ipq807x)
  DEVICE_TITLE := JD BE6500 (IPQ5332)
  DEVICE_DTS := qcom,ipq5332-jd-be6500
  DEVICE_PACKAGES := kmod-ath11k-ct kmod-qca-ppe kmod-qca-nss-drv kmod-qca-nss-gmac kmod-thermal-qcom
  IMAGE_SIZE := 256m
  IMAGES := sysupgrade.bin factory.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-to $(IMAGE_SIZE) | check-size $(IMAGE_SIZE)
  IMAGE/factory.bin := append-kernel | append-rootfs | pad-to $(IMAGE_SIZE) | check-size $(IMAGE_SIZE)
endef
TARGET_DEVICES += jd-be6500
