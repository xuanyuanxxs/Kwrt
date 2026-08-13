#!/bin/sh

# 定义配置文件路径
SYSTEM_CONFIG="/etc/config/system"

# --- 1. 生成随机的6个小写字母 ---
NEW_HOSTNAME=$(tr -dc 'a-z' < /dev/urandom | head -c 6)

echo "✅ 生成新的主机名: ${NEW_HOSTNAME}"

# --- 2. 使用 uci 修改配置 ---
uci set system.@system[0].hostname="${NEW_HOSTNAME}"

echo "📝 配置修改成功: ${SYSTEM_CONFIG} 中的 option hostname 已更新。"

# --- 3. 提交更改并应用 ---
uci commit system

# 重载 system 服务以应用新的主机名
#/etc/init.d/system reload

echo "✨ 新的主机名已应用。"

# --- 4. 验证 ---
#echo "--- 验证 ---"
#uci get system.@system[0].hostname
