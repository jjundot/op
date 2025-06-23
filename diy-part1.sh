#!/bin/bash
# 使用清华大学镜像源
sed -i 's#https://git.openwrt.org#https://github.com/openwrt#' include/feeds.mk
sed -i 's#http://downloads.openwrt.org#https://mirrors.tuna.tsinghua.edu.cn/openwrt#' feeds.conf.default

# 添加常用软件包源（国内优化）
echo "src-git kenzo https://gitee.com/kenzok8/openwrt-packages" >> feeds.conf.default
echo "src-git small https://gitee.com/kenzok8/small" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall" >> feeds.conf.default
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf.default

# 添加luci-theme-argon主题（国内加速）
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
