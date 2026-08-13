#!/bin/sh
set -e

# 生成随机 MAC (10:04:C2 开头)
rand_byte() {
    printf "%02X" $((RANDOM % 256))
}

WAN_MAC=$(printf "8C:DE:F9:%s:%s:%s" \
    "$(rand_byte)" \
    "$(rand_byte)" \
    "$(rand_byte)")

# 获取 interface 对应的 device
get_iface_dev() {
    uci -q get network.$1.device || uci -q get network.$1.ifname
}

WAN_DEV=$(get_iface_dev wan)

[ -z "$WAN_DEV" ] && echo "WAN device not found" && exit 1

echo "WAN device: $WAN_DEV"

# 获取 device 块，如果不存在就创建
get_device_section() {
    for sec in $(uci show network | grep "=device" | cut -d= -f1); do
        name=$(uci -q get $sec.name)
        [ "$name" = "$1" ] && echo "$sec" && return
    done

    sec="network.@device[-1]"
    uci add network device
    uci set $sec.name="$1"
    echo "$sec"
}

WAN_SEC=$(get_device_section "$WAN_DEV")

uci set $WAN_SEC.macaddr="$WAN_MAC"
uci commit network

echo "WAN MAC: $WAN_MAC"
echo "network config updated"

#/etc/init.d/network reload