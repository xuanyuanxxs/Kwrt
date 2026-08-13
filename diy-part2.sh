#!/usr/bin/env bash
###############################################################################
# Kwrt 自定义固件 - diy-part2.sh
#
# 在 fork 的 kiddin9/Kwrt 仓库根目录(因为大多数 Actions-OpenWrt 衍生 workflow
# 在 feeds install 之后调用这个脚本)放置本文件。
#
# 工作机制:把用户包追加到 .config,运行 `make defconfig` 让 build 系统解析依赖。
###############################################################################

cat >> .config << 'EOF'

# =============================================================================
#  用户路由器 (xiaomi mi-router-cr660x, Kwrt 25.12) opkg list-installed
#  对应追加进 .config 的非默认包
# =============================================================================

# Shell / 编辑 / 网络基础
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_wget-ssl=y

# LuCI 主框架 + 主题
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-mod-admin-full=y

# LuCI 应用 (用户实际安装的非默认项)
CONFIG_PACKAGE_luci-app-advancedplus=y
CONFIG_PACKAGE_luci-app-fan=y
CONFIG_PACKAGE_luci-app-filemanager=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-package-manager=y
CONFIG_PACKAGE_luci-app-syscontrol=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-wifihistory=y
CONFIG_PACKAGE_luci-app-wizard=y

# VPN / 代理 (这是你这台的核心)
CONFIG_PACKAGE_passwall=y
CONFIG_PACKAGE_passwall_server=y
CONFIG_PACKAGE_shadowsocks-libev=y
CONFIG_PACKAGE_wireguard-tools=y

# 内核模块 (这些一般需要显式启用)
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-wireguard=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-mt7915e=y
CONFIG_PACKAGE_kmod-mt7915-firmware=y

# 其他 Kwrt 风格工具
CONFIG_PACKAGE_my-default-settings=y
CONFIG_PACKAGE_shellsync=y
CONFIG_PACKAGE_ttyd=y
CONFIG_PACKAGE_ubihealthd=y
CONFIG_PACKAGE_wifi-scripts=y
CONFIG_PACKAGE_zram-swap=y
EOF

# 让 build 系统解析并写入新依赖
make defconfig
