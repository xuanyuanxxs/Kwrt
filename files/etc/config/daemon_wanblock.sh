# 自动恢复 wanblock 热插拔脚本
HOTPLUG="/etc/hotplug.d/iface/99-wanblock"
BACKUP="/etc/config/99-wanblock"

if [ ! -f "$HOTPLUG" ] && [ -f "$BACKUP" ]; then
    mkdir -p /etc/hotplug.d/iface
    cp "$BACKUP" "$HOTPLUG"
    chmod +x "$HOTPLUG"
fi