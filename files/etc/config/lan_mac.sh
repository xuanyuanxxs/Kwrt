#!/bin/sh
set -e

# ============================================================
# 生成随机 MAC
# 固定前 3 个字节：34:47:D4
# 后 3 个字节使用 $RANDOM
# ============================================================

rand_byte() {
    printf "%02X" $((RANDOM % 256))
}

LAN_MAC=$(printf "8C:DE:F9:%s:%s:%s" \
    "$(rand_byte)" \
    "$(rand_byte)" \
    "$(rand_byte)")

echo "========================================"
echo "Generated LAN MAC: $LAN_MAC"
echo "========================================"


# ============================================================
# 获取 interface 对应的 device
# ============================================================

get_iface_dev() {
    uci -q get network.$1.device || \
    uci -q get network.$1.ifname
}

LAN_DEV=$(get_iface_dev lan)

[ -z "$LAN_DEV" ] && {
    echo "LAN device not found"
    exit 1
}

echo "LAN device: $LAN_DEV"


# ============================================================
# 获取 device 配置块
# 如果不存在则创建
# ============================================================

get_device_section() {
    for sec in $(uci show network | grep "=device" | cut -d= -f1); do
        name=$(uci -q get "$sec.name")
        [ "$name" = "$1" ] && {
            echo "$sec"
            return
        }
    done

    sec=$(uci add network device)
    uci set "$sec.name=$1"
    echo "$sec"
}


# ============================================================
# 设置指定 device 的 UCI MAC
# ============================================================

set_device_mac() {
    DEV="$1"

    [ -z "$DEV" ] && return

    SEC=$(get_device_section "$DEV")

    uci set "$SEC.macaddr=$LAN_MAC"

    echo "UCI: $DEV -> $LAN_MAC"
}


# ============================================================
# 1. 设置 br-lan 本身的 MAC
# ============================================================

set_device_mac "$LAN_DEV"


# ============================================================
# 2. 获取 br-lan 当前绑定的所有接口
#
# WiFi 接口：
#   phy0-ap0
#   phy1-ap0
#   phy0-ap1
#   phy1-ap1
#   ...
#
# 全部跳过，不修改 WiFi MAC。
# ============================================================

BR_DIR="/sys/class/net/$LAN_DEV/brif"

if [ -d "$BR_DIR" ]; then

    echo ""
    echo "Bridge ports:"

    for PORT_PATH in "$BR_DIR"/*; do

        [ -e "$PORT_PATH" ] || continue

        PORT=$(basename "$PORT_PATH")

        # ----------------------------------------------------
        # 跳过 WiFi 接口
        #
        # 匹配：
        # phy0-ap0
        # phy1-ap0
        # phy0-ap1
        # phy1-ap1
        # phy0-ap2
        # ...
        # ----------------------------------------------------

        case "$PORT" in
            phy*-ap*)
                echo "  SKIP WiFi: $PORT"
                continue
                ;;
        esac

        echo "  LAN: $PORT"

        # 写入 UCI
        set_device_mac "$PORT"

    done

else
    echo "WARNING: $BR_DIR not found"
fi


# ============================================================
# 保存 UCI 配置
# ============================================================

uci commit network

echo ""
echo "network config updated"


# ============================================================
# 3. 立即修改当前运行中的 MAC
#
# br-lan：修改
# 有线 bridge port：修改
# WiFi phy*-ap*：跳过
# ============================================================

echo ""
echo "Applying MAC addresses..."

# 修改 br-lan
ip link set dev "$LAN_DEV" address "$LAN_MAC" 2>/dev/null || \
    echo "WARNING: failed to set MAC on $LAN_DEV"

echo "$LAN_DEV -> $LAN_MAC"


# 修改 br-lan 下的有线接口
if [ -d "$BR_DIR" ]; then

    for PORT_PATH in "$BR_DIR"/*; do

        [ -e "$PORT_PATH" ] || continue

        PORT=$(basename "$PORT_PATH")

        # 跳过 WiFi
        case "$PORT" in
            phy*-ap*)
                echo "SKIP WiFi: $PORT"
                continue
                ;;
        esac

        ip link set dev "$PORT" address "$LAN_MAC" 2>/dev/null || \
            echo "WARNING: failed to set MAC on $PORT"

        echo "$PORT -> $LAN_MAC"

    done

fi


echo ""
echo "========================================"
echo "MAC configuration completed"
echo ""
echo "Common LAN MAC:"
echo "$LAN_MAC"
echo ""
echo "WiFi interfaces were NOT modified."
echo "========================================"

# ============================================================
# 如需重新加载网络，取消下面注释
#
# /etc/init.d/network reload
# ============================================================