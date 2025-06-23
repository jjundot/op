#!/bin/bash
# 脚本功能：添加软件源和主题，配置镜像加速（替换为GitHub源）

# 使用清华大学镜像源
sed -i 's#https://git.openwrt.org#https://github.com/openwrt#' include/feeds.mk
sed -i 's#http://downloads.openwrt.org#https://mirrors.tuna.tsinghua.edu.cn/openwrt#' feeds.conf.default

# 添加常用软件包源（替换Gitee源为GitHub源）
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall" >> feeds.conf.default
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf.default
echo "src-git lienol https://github.com/Lienol/openwrt-package" >> feeds.conf.default

# 添加luci-theme-argon主题（国内加速）
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# 添加SmartDNS
echo "src-git smartdns https://github.com/pymumu/luci-app-smartdns" >> feeds.conf.default

# 添加upx/host支持
echo "src-git utils https://github.com/openwrt/packages;openwrt-23.05" >> feeds.conf.default
