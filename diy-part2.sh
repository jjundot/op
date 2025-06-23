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

# 调整防火墙规则
cat > package/network/config/firewall/files/firewall.user << EOF
# 启用BBR拥塞控制
echo "tcp_bbr" > /etc/modules-load.d/tcp-bbr.conf

# 限制ICMP洪水攻击
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
EOF







