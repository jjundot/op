#!/bin/bash
cd openwrt

# 修改默认配置
sed -i 's/192.168.1.1/192.168.128.1/g' package/base-files/files/bin/config_generate  # 修改默认IP
sed -i 's/OpenWrt/JD-BE6500/g' package/base-files/files/bin/config_generate  # 修改主机名
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate  # 设置时区为上海

# 优化：修复重复添加主题的问题
# 已在diy-part1中添加，此处无需重复
# git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 调整无线驱动参数（针对IPQ5332）
# 优化：使用更准确的无线配置方式
cat > package/kernel/mac80211/files/lib/wifi/mac80211.sh << EOF
#!/bin/sh

set_wifi() {
  local device=\$1
  local section=\$2
  local channel=\${3:-auto}
  local ssid="JD-BE6500-\${device}"
  local key="YourWiFiPassword"
  
  uci -q delete wireless.\${section}
  uci set wireless.\${section}=wifi-device
  uci set wireless.\${section}.type=mac80211
  uci set wireless.\${section}.channel=\${channel}
  uci set wireless.\${section}.hwmode=11ax
  uci set wireless.\${section}.path=\$(cat /sys/class/ieee80211/\${device}/device/path 2>/dev/null || echo "pci0000:00/0000:00:00.0")
  uci set wireless.\${section}.htmode=VHT80
  uci set wireless.\${section}.country=CN
  uci set wireless.\${section}.txpower=23
  uci set wireless.\${section}.he_bandwidth=80
  uci set wireless.\${section}.he_su_beamformer=1
  uci set wireless.\${section}.he_su_beamformee=1
  
  uci -q delete wireless.\${section}_ap
  uci set wireless.\${section}_ap=wifi-iface
  uci set wireless.\${section}_ap.device=\${section}
  uci set wireless.\${section}_ap.network=lan
  uci set wireless.\${section}_ap.mode=ap
  uci set wireless.\${section}_ap.ssid=\${ssid}
  uci set wireless.\${section}_ap.encryption=psk2+ccmp
  uci set wireless.\${section}_ap.key=\${key}
}

# 配置2.4G和5G
set_wifi radio0 mt7622-2g 11
set_wifi radio1 mt7622-5g auto
EOF

# 启用Turbo ACC网络加速（优化）
# 移除已弃用的SFE选项
sed -i 's/option flow_offload 0/option flow_offload 1/g' package/network/config/firewall/files/firewall.config
sed -i '/option sfe 0/d' package/network/config/firewall/files/firewall.config

# 添加常用软件包（优化：使用模块化方法）
mkdir -p package/custom
git clone https://github.com/xiaorouji/openwrt-passwall package/custom/passwall
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/custom/adguardhome
git clone https://github.com/cnsilvan/luci-app-samba4 package/custom/samba4
git clone https://github.com/lisaac/luci-app-dockerman package/custom/dockerman

# 优化系统参数（合并重复配置）
cat > package/base-files/files/etc/sysctl.conf << EOF
# 基础系统优化
vm.min_free_kbytes=8192
vm.swappiness=10
fs.file-max=65536

# 网络优化
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1

# 内存优化
vm.overcommit_memory=1
vm.overcommit_ratio=80
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF

# 调整防火墙规则
cat > package/network/config/firewall/files/firewall.user << EOF
# 启用BBR拥塞控制
echo "tcp_bbr" > /etc/modules-load.d/tcp-bbr.conf

# 限制ICMP洪水攻击
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# IPQ5332专用网络优化
iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark
iptables -t mangle -A POSTROUTING -j CONNMARK --save-mark
EOF

# 调整系统内存分配（针对1GB RAM设备）
sed -i 's/CONFIG_DEFAULT_TARGET_OPTIMIZATION="-Os"/CONFIG_DEFAULT_TARGET_OPTIMIZATION="-O2"/g' .config
sed -i 's/CONFIG_USE_MUSL_DYNAMIC_LINKER=y/# CONFIG_USE_MUSL_DYNAMIC_LINKER is not set/g' .config

# 优化：修正分区设置（使用正确的IPQ5332分区）
sed -i 's/64k/128k/g' target/linux/ipq807x/image/generic.mk  # 增大内核分区
sed -i 's/128k/512k/g' target/linux/ipq807x/image/generic.mk  # 增大rootfs分区

# 优化内核参数（移除不必要的选项）
sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/g' .config
sed -i 's/CONFIG_KERNEL_IKHEADERS=y/# CONFIG_KERNEL_IKHEADERS is not set/g' .config

# 启用Turbo ACC网络加速（完整配置）
pushd package/custom
git clone https://github.com/chenmozhijin/turboacc.git
cd turboacc
./build.sh
popd

# 添加SmartDNS
pushd package/custom
git clone -b lede https://github.com/pymumu/luci-app-smartdns.git
popd

# 配置SmartDNS为默认DNS
sed -i 's/option resolvfile/# option resolvfile/g' package/network/services/dnsmasq/files/dhcp.conf
sed -i '/# option resolvfile/a\option server \"/#/127.0.0.1#5353\"' package/network/services/dnsmasq/files/dhcp.conf
