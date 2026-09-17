echo "=== 已安装的桌面相关软件包 ==="
dpkg-query -W -f='${binary:Package}\n' 2>/dev/null | \
  grep -Ei 'ubuntu-desktop|gnome|kde|plasma|xfce|lxde|lxqt|mate|cinnamon|budgie|xorg|wayland|display-manager' | \
  sort

echo
echo "=== 当前默认/正在使用的桌面会话 ==="
echo "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
echo "XDG_SESSION_DESKTOP=$XDG_SESSION_DESKTOP"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"

echo
echo "=== 当前登录管理器 ==="
systemctl status display-manager --no-pager 2>/dev/null || true

echo
echo "=== 已安装的桌面任务包 ==="
apt list --installed 2>/dev/null | \
  grep -Ei 'desktop|gnome|xfce|lxqt|lxde|mate|cinnamon|budgie' | \
  head -100