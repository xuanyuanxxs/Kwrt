#!/bin/sh
set -e

# 文件路径
NETFILE="/etc/config/network"

# 生成随机 MAC (02 开头 = 本地地址)
# 生成 1 个 00–FF 的 16 进制字节（ASH 兼容）
rand_byte() {
    printf "%02X" $((RANDOM % 256))
}

# 固定前缀 + 3 个随机字节 = 6 字节 MAC
MAC_BASE=$(printf "50:33:F0:%s:%s:%s" \
    "$(rand_byte)" \
    "$(rand_byte)" \
    "$(rand_byte)")

LAN_MAC="${MAC_BASE}"
WAN_MAC="$(printf "%s:%02X" "${MAC_BASE%:*}" $((0x${MAC_BASE##*:} + 1)))"

# 获取 interface 对应的 device
get_iface_dev() {
    uci -q get network.$1.device || uci -q get network.$1.ifname
}

LAN_DEV=$(get_iface_dev lan)
WAN_DEV=$(get_iface_dev wan)

[ -z "$LAN_DEV" ] && echo "LAN device not found" && exit 1
[ -z "$WAN_DEV" ] && echo "WAN device not found" && exit 1

echo "LAN device: $LAN_DEV"
echo "WAN device: $WAN_DEV"

# 获取 device 块，如果不存在就创建
get_device_section() {
    for sec in $(uci show network | grep "=device" | cut -d= -f1); do
        name=$(uci -q get $sec.name)
        [ "$name" = "$1" ] && echo "$sec" && return
    done
    # 不存在就创建
    sec="network.@device[-1]"  # 最后追加
    uci add network device
    uci set $sec.name="$1"
    echo "$sec"
}

LAN_SEC=$(get_device_section "$LAN_DEV")
WAN_SEC=$(get_device_section "$WAN_DEV")

# 设置 MAC
uci set $LAN_SEC.macaddr="$LAN_MAC"
uci set $WAN_SEC.macaddr="$WAN_MAC"
uci commit network

echo "LAN MAC: $LAN_MAC"
echo "WAN MAC: $WAN_MAC"
echo "network config updated"

# 应用配置
#/etc/init.d/network reload
