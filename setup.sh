#!/usr/bin/env bash
# setup.sh — 一键还原 dotfiles (按入口分组: $HOME 层 / /etc 层)
#
# 用法:
#   ./setup.sh               # 从本仓库目录运行
#   DOTFILES=/path ./setup.sh  # 指定仓库路径 (默认取脚本所在目录)
#
# 原理: stow 的 --target 是调用级全局选项, 无法按包区分。
#       因此按"配置入口"分两个 stow 目录组, 每组用各自 .stowrc 携带 --target:
#         home/   -> --target=$HOME  (用户级配置, 无需 sudo)
#         system/ -> --target=/etc   (系统级配置, 需 sudo)
set -euo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ---- 1. 依赖检查 ------------------------------------------------------------
for c in stow; do
    command -v "$c" >/dev/null 2>&1 || { echo "错误: 缺少依赖 '$c', 请先安装 (pacman -S $c)"; exit 1; }
done

# ---- 2. 本地(用户)层: home/ -> $HOME ---------------------------------------
# 自动发现 home/ 下的所有包 (含 . 的隐藏包也要 stow)
home_pkgs=();
for d in "$DOTFILES"/home/*; do
    [ -e "$d" ] || continue
    home_pkgs+=( "$(basename "$d")" )
done
if [ "${#home_pkgs[@]}" -gt 0 ]; then
    echo "==> stow 用户层包 (target=\$HOME): ${home_pkgs[*]}"
    stow -d "$DOTFILES/home" --target="$HOME" "${home_pkgs[@]}"
fi

# ---- 3. 系统层: system/ -> /etc (需要 sudo) --------------------------------
system_pkgs=();
for d in "$DOTFILES"/system/*; do
    [ -e "$d" ] || continue
    # 排除目录组自身的 .stowrc 等控制文件
    case "$(basename "$d")" in .stowrc|.stow*) continue;; esac
    system_pkgs+=( "$(basename "$d")" )
done
if [ "${#system_pkgs[@]}" -gt 0 ]; then
    echo "==> stow 系统层包 (target=/etc, 需要 sudo): ${system_pkgs[*]}"
    sudo -v || { echo "错误: sudo 验证失败"; exit 1; }
    stow -d "$DOTFILES/system" --target=/etc "${system_pkgs[@]}"
fi

# ---- 4. 按包启用对应服务 (可扩展) ------------------------------------------
# 新增项: 若包已 stow 且服务存在, 则 enable --now
enable_service() {
    local svc="$1"; shift
    if { [ -f "/etc/systemd/system/$svc" ] || [ -f "/usr/lib/systemd/system/$svc" ]; }; then
        echo "==> 启用服务 $svc"
        sudo systemctl enable --now "$svc"
    else
        echo "--> 跳过 $svc (服务单元不存在)"
    fi
}

# keyd 是包索引; 这里显式列出需要启用/校验的服务及其包名
if [ -d "$DOTFILES/system/keyd" ]; then
    enable_service "keyd.service"
fi

echo "==> 完成。"
echo "    检验: stow -v 输出; ~/.config/foot 链接; /etc/keyd/default.conf 链接"
