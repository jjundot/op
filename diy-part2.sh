#!/bin/bash
cd openwrt

# 修改默认配置
sed -i 's/192.168.1.1/192.168.128.1/g' package/base-files/files/bin/config_generate  # 修改默认IP
sed -i 's/OpenWrt/JD-BE6500/g' package/base-files/files/bin/config_generate  # 修改主机名
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate  # 设置时区为上海

# 添加自定义主题
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 调整无线驱动参数（针对IPQ5322）
sed -i 's/wifi_ssid=OpenWrt/wifi_ssid=JD-BE6500-OpenWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 启用Turbo ACC网络加速
sed -i 's/option flow_offload 0/option flow_offload 1/g' package/network/config/firewall/files/firewall.config
sed -i 's/option sfe 0/option sfe 1/g' package/network/config/firewall/files/firewall.config

# 添加常用软件包
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/adguardhome
git clone https://github.com/cnsilvan/luci-app-samba4 package/samba4
git clone https://github.com/lisaac/luci-app-dockerman package/dockerman

# 优化系统参数
cat >> package/base-files/files/etc/sysctl.conf << EOF
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
vm.min_free_kbytes=8192
vm.swappiness=10
fs.file-max=65536
EOF

# 优化网络参数
cat >> package/base-files/files/etc/sysctl.conf << EOF
# 网络优化
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
EOF

# 优化Wi-Fi 7 (IPQ5322/QCN6224) 驱动参数
cat >> package/kernel/mac80211/files/lib/wifi/mac80211.sh << EOF
  option country 'CN'
  option channel 'auto'
  option hwmode '11ax'
  option path 'pci0000:00/0000:00:00.0'
  option htmode 'VHT80'
  option he_bandwidth '80'
  option he_su_beamformer '1'
  option he_su_beamformee '1'
EOF

# 设置5G频段默认SSID和密码
sed -i 's/wifi_ssid=JD-BE6500-OpenWrt/wifi_ssid=JD-BE6500-5G/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i '/set wireless.default_radio${devidx}.encryption=none/a\set wireless.default_radio${devidx}.key=YourWiFiPassword' package/kernel/mac80211/files/lib/wifi/mac80211.sh
# 调整防火墙规则
cat > package/network/config/firewall/files/firewall.user << EOF
# 启用BBR拥塞控制
echo "tcp_bbr" > /etc/modules-load.d/tcp-bbr.conf

# 限制ICMP洪水攻击
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
EOF


#  调整系统内存分配（针对1GB RAM设备）
sed -i 's/CONFIG_DEFAULT_TARGET_OPTIMIZATION="-Os"/CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O2"/g' .config
sed -i 's/CONFIG_USE_MUSL_DYNAMIC_LINKER=y/# CONFIG_USE_MUSL_DYNAMIC_LINKER is not set/g' .config

#  增大文件系统空间
sed -i 's/64k/256k/g' target/linux/qca-ipq807x/image/generic.mk  # 增大内核分区
sed -i 's/128k/512k/g' target/linux/qca-ipq807x/image/generic.mk  # 增大rootfs分区

#  优化内核参数
sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/g' .config
sed -i 's/CONFIG_KERNEL_IKHEADERS=y/# CONFIG_KERNEL_IKHEADERS is not set/g' .config




