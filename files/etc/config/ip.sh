#!/bin/sh
set -e

NETFILE="/etc/config/network"

# 必须包含 rand_byte 函数
rand_byte() {
    # 读一个字节，转成十进制
    C=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null)
    printf "%d" "'$C'"
}

# 生成随机 LAN IP (192.168.2.1 - 192.168.254.1)
# 使用 expr 进行算术运算，兼容 ASH
BYTE_VAL=$(rand_byte)
MOD_VAL=$(expr $BYTE_VAL % 253)
RAND_X=$(expr $MOD_VAL + 2)
RAND_IP="192.168.$RAND_X.1"

# 修改 LAN 段的 ipaddr
sed -i "/config interface 'lan'/,/^config / s/^\(\s*option ipaddr\s*\).*/\1 '$RAND_IP'/" "$NETFILE"
echo ">>> 随机 LAN IP: $RAND_IP"

echo ">>> 修改完成，已更新 $NETFILE"

# 应用配置
#/etc/init.d/network reload
