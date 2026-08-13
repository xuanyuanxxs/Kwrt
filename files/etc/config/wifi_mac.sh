#!/bin/sh
set -e

# 生成随机 MAC (10:04:C2 开头)
rand_byte() {
    printf "%02X" $((RANDOM % 256))
}

MAC_BASE=$(printf "8C:DE:F9:%s:%s:%s" \
    "$(rand_byte)" \
    "$(rand_byte)" \
    "$(rand_byte)")

PHY0_MAC="${MAC_BASE}"
PHY1_MAC="$(printf "%s:%02X" "${MAC_BASE%:*}" $((0x${MAC_BASE##*:} + 1)))"

echo "phy0-ap0 MAC: $PHY0_MAC"
echo "phy1-ap0 MAC: $PHY1_MAC"

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

PHY0_SEC=$(get_device_section "phy0-ap0")
PHY1_SEC=$(get_device_section "phy1-ap0")

uci set $PHY0_SEC.macaddr="$PHY0_MAC"
uci set $PHY1_SEC.macaddr="$PHY1_MAC"

uci commit network

echo "network config updated"

#/etc/init.d/network reload