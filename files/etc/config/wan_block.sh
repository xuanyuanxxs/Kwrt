#!/bin/sh

WAN_DEV=$(uci -q get network.wan.device)
[ -z "$WAN_DEV" ] && WAN_DEV=$(uci -q get network.wan.ifname)

WAN_IP=$(ip -4 addr show $WAN_DEV | awk '/inet /{print $2}' | cut -d/ -f1)
PREFIX=$(ip -4 addr show $WAN_DEV | awk '/inet /{print $2}' | cut -d/ -f2)

GW=$(ip route | grep default | grep $WAN_DEV | awk '{print $3}')

NET=$(ipcalc.sh $WAN_IP/$PREFIX | grep NETWORK | cut -d= -f2)

echo "WAN_IP=$WAN_IP"
echo "GW=$GW"
echo "NET=$NET/$PREFIX"

nft delete table inet wanblock 2>/dev/null

nft add table inet wanblock

nft add chain inet wanblock forward '{ type filter hook forward priority -5; }'

# 允许LAN访问网关
nft add rule inet wanblock forward ip daddr $GW accept

# 允许LAN访问WAN自身
nft add rule inet wanblock forward ip daddr $WAN_IP accept

# 丢弃LAN访问WAN网段其它设备
nft add rule inet wanblock forward ip daddr $NET/$PREFIX drop

echo "规则已加载"
