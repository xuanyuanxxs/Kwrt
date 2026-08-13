#!/usr/bin/env bash
###############################################################################
# 把路由器当前的 /etc/config 拉到本地 files/etc/config 目录
#
# 用法:
#   1) cd 进你 fork 的 kiddin9/Kwrt 根目录
#   2) ./backup-router-configs.sh
#      或者:
#         ROUTER_PASS=xxx ./backup-router-configs.sh
###############################################################################
set -euo pipefail

ROUTER_IP="${ROUTER_IP:-192.168.31.1}"
ROUTER_USER="${ROUTER_USER:-root}"

if [ -z "${ROUTER_PASS:-}" ]; then
  read -s -p "请输入 ${ROUTER_USER}@${ROUTER_IP} 的 SSH 密码: " ROUTER_PASS
  echo
fi
export SSHPASS="$ROUTER_PASS"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
SSH="sshpass -e ssh $SSH_OPTS"
SCP="sshpass -e scp -O $SSH_OPTS"

if ! $SSH "$ROUTER_USER@$ROUTER_IP" "true" 2>/dev/null; then
  echo "SSH 不可达 - 检查 IP/用户名/密码/防火墙"
  exit 1
fi

mkdir -p files/etc/config

# /etc/config 整目录拉过来 — 含你路由器上的所有 UCI 配置+你的 .sh 脚本
$SCP -r "$ROUTER_USER@$ROUTER_IP:/etc/config/." files/etc/config/

# (可选)如果你想再拉额外的路径:
#   /etc/rc.local          — 如果 build 系统没把 files/etc/rc.local 烤进去,显式拉一份覆盖
#   /etc/firewall.user
#   /etc/crontabs/
#   /etc/dropbear/         — SSH 主机密钥,如果想让多台路由器共用同一个密钥
# $SCP "$ROUTER_USER@$ROUTER_IP:/etc/rc.local"          files/etc/      || true
# $SCP -r "$ROUTER_USER@$ROUTER_IP:/etc/crontabs/."     files/etc/crontabs/  || true
# $SCP -r "$ROUTER_USER@$ROUTER_IP:/etc/dropbear/."    files/etc/dropbear/ || true

echo
echo "✔ 拉取完成,以下文件现在已经在 files/etc/config/:"
find files/etc/config -type f | sort | sed 's/^/   /'

cat <<EOF

下一步:
   1. 在 files/etc/config/ 目录里检查 — 有没有你不想在多台机器上相同的东西
      (例如 /etc/config/system 的 hostname、/etc/config/network 的 IP)
   2. 把对每台机器都期望相同的配置文件留下来
   3. 然后继续下面 README 里写的 commit+push 步骤
EOF
