#!/bin/bash
# diy-part1.sh - IPQ5332编译前优化脚本

echo "开始执行IPQ5332编译前优化..."
cd $OPENWRT_PATH

# ===== 基础配置优化 =====
echo "配置编译基础参数..."
# 使用清华大学镜像源
sed -i 's#https://git.openwrt.org#https://github.com/openwrt#' include/feeds.mk
sed -i 's#http://downloads.openwrt.org#https://mirrors.tuna.tsinghua.edu.cn/openwrt#' feeds.conf.default

# 添加常用软件包源（使用GitHub源）
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall" >> feeds.conf.default
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf.default
echo "src-git lienol https://github.com/Lienol/openwrt-package" >> feeds.conf.default

# 添加SmartDNS
echo "src-git smartdns https://github.com/pymumu/luci-app-smartdns" >> feeds.conf.default

# 添加upx/host支持
echo "src-git utils https://github.com/openwrt/packages;openwrt-23.05" >> feeds.conf.default

# ===== 无线驱动优化 =====
echo "优化IPQ5332驱动加载顺序..."
cat > package/base-files/files/etc/modules-load.d/ath11k.conf << EOF
ath11k_pci
ath11k_core
ath11k_hw
EOF

# ===== WiFi默认配置优化 =====
echo "配置WiFi默认参数..."
cat > package/base-files/files/etc/config/wireless << EOF
config wifi-device 'radio0'
  option type 'mac80211'
  option path 'pci0000:00/0000:00:00.0'
  option band '5GHz'
  option channel 'auto'
  option hwmode '11ax'
  option htmode 'VHT80'
  option he_gi='1600ns'
  option he_mcs='11'
  option country 'CN'
  option txpower '23'
  option disabled '0'

config wifi-iface 'default_radio0'
  option device 'radio0'
  option network 'lan'
  option mode 'ap'
  option ssid 'JD-BE6500-5G'
  option encryption 'psk2+ccmp'
  option key 'OpenWrt-Default-Password'
  option isolate '0'

config wifi-device 'radio1'
  option type 'mac80211'
  option path 'pci0000:00/0000:00:01.0'
  option band '2.4GHz'
  option channel 'auto'
  option hwmode '11ax'
  option htmode 'HT40+'
  option country 'CN'
  option txpower '20'
  option disabled '0'
  option noscan '1'

config wifi-iface 'default_radio1'
  option device 'radio1'
  option network 'lan'
  option mode 'ap'
  option ssid 'JD-BE6500-2.4G'
  option encryption 'psk2+ccmp'
  option key 'OpenWrt-Default-Password'
  option isolate '0'
EOF

# ===== 硬件加速优化 =====
echo "优化PPE硬件加速..."
cat > package/base-files/files/etc/init.d/hw_accel << EOF
#!/bin/sh /etc/rc.common
START=90

start() {
  echo 1 > /sys/module/qca_ppe/parameters/ppe_enable
  echo 1 > /sys/module/qca_nss/parameters/nss_enable
  echo 1 > /sys/module/qca_nss_gmac/parameters/enable_hw_offload
  echo "IPQ5332硬件加速已启用"
}
EOF
chmod +x package/base-files/files/etc/init.d/hw_accel

# ===== 系统性能优化 =====
echo "配置系统性能优化..."
# 调整系统参数
cat > package/base-files/files/etc/sysctl.conf << EOF
# 网络优化
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.ip_local_port_range=1024 65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# 文件系统优化
fs.file-max=131072
fs.inotify.max_user_instances=8192

# 内存优化
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.min_free_kbytes=16384
EOF

# ===== 添加luci-theme-argon主题 =====
echo "添加Argon主题..."
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# ===== 配置默认主题为Argon =====
echo "配置默认主题..."
cat > package/lean/default-settings/files/zzz-default-settings << EOF
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
exit 0
EOF

# ===== 调整防火墙规则 =====
echo "优化防火墙规则..."
cat > package/base-files/files/etc/firewall.user << EOF
# 启用NAT加速
echo 1 > /proc/sys/net/netfilter/nf_conntrack_tcp_be_liberal

# 优化TCP连接跟踪
echo 65536 > /sys/module/nf_conntrack/parameters/hashsize

# 启用BBR拥塞控制
echo "tcp_bbr" > /etc/modules-load.d/tcp-bbr.conf
EOF

# ===== IPQ5332温度管理 =====
echo "配置IPQ5332温度管理..."
cat > package/base-files/files/etc/thermal.conf << EOF
# IPQ5332温度管理配置
chip0 {
    trip_point_0 = 75
    trip_point_1 = 85
    trip_point_2 = 95
}
EOF

echo "IPQ5332编译前优化完成"
