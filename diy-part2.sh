#!/bin/bash
cd openwrt

# 修改默认IP
sed -i 's/192.168.1.1/192.168.128.1/g' package/base-files/files/bin/config_generate

# 添加自定义主题
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 调整无线驱动参数（针对IPQ5322）
sed -i 's/wifi_ssid=OpenWrt/wifi_ssid=JD-BE6500-OpenWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
