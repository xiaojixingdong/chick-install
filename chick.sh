#!/usr/bin/env bash
# ============================================================
#  🐤 Chick 自动安装脚本 --1
#  开发者：小鸡行动 (xiaojixingdong)
#  联系邮箱：xiaojixingdong@gmail.com
#  适用平台：Codespaces / Linux / macOS / WSL / Termux
# ============================================================

set -euo pipefail

# ---------- 颜色 ----------
GREEN='\033[92m'; YELLOW='\033[93m'; CYAN='\033[96m'; RED='\033[91m'; RESET='\033[0m'

# ---------- 配置 ----------
CHICK_HOME="$HOME/.chick"
CHICK_BIN="$CHICK_HOME/chick.sh"
STATE_FILE="$CHICK_HOME/state"
SCRIPT_URL="https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh"

# 可选软件列表
APP_LIST=(
    "Google Chrome"
    "Firefox"
    "微信"
    "QQ"
    "Android Studio"
    "VS Code Server"
    "Docker"
    "Node.js"
    "Python"
    "中文输入法 (Fcitx5)"
)

# 初始化状态目录
mkdir -p "$CHICK_HOME"
[ -f "$STATE_FILE" ] || echo "desktop=false" > "$STATE_FILE"

# ---------- 系统检测 ----------
detect_os() {
    if [ -n "${TERMUX_VERSION:-}" ] || [[ "${PREFIX:-}" == *"com.termux"* ]]; then
        echo "termux"
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo "macos"
    elif [ -n "${CODESPACES:-}" ]; then
        echo "codespaces"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "linux"
    fi
}
OS_TYPE=$(detect_os)

# ---------- 状态管理 ----------
is_desktop_installed() { grep -q "^desktop=true" "$STATE_FILE" 2>/dev/null; }
set_desktop_installed() { sed -i 's/^desktop=.*/desktop=true/' "$STATE_FILE"; }

# ---------- 安装 gum (精美菜单依赖) ----------
install_gum() {
    if command -v gum &>/dev/null; then return; fi
    echo -e "${CYAN}>>> 首次运行，正在安装界面美化组件 gum...${RESET}"
    if [ "$OS_TYPE" = "termux" ]; then
        pkg install -y gum
    elif [ "$OS_TYPE" = "macos" ]; then
        brew install gum 2>/dev/null || true
    else
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt update -qq && sudo apt install -y gum
    fi
}

# ---------- 小鸡 Banner ----------
show_banner() {
    clear 2>/dev/null || true
    echo -e "${YELLOW}"
    cat << "EOF"
   ██████╗██╗  ██╗██╗ ██████╗██╗  ██╗
  ██╔════╝██║  ██║██║██╔════╝██║ ██╔╝
  ██║     ███████║██║██║     █████╔╝ 
  ██║     ██╔══██║██║██║     ██╔═██╗ 
  ╚██████╗██║  ██║██║╚██████╗██║  ██╗
   ╚═════╝╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "${CYAN}   ╭──────────────────────────────╮${RESET}"
    echo -e "${CYAN}   │${YELLOW}      🐤  你好呀！我是Chick    ${CYAN}│${RESET}"
    echo -e "${CYAN}   │${YELLOW}     你的云端桌面小助手        ${CYAN}│${RESET}"
    echo -e "${CYAN}   ╰──────────────────────────────╯${RESET}"
    echo ""
    echo -e "${GREEN}──────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}开发者：${RESET}小鸡行动"
    echo -e "  ${CYAN}联系邮箱：${RESET}xiaojixingdong@gmail.com"
    echo -e "  ${YELLOW}欢迎发送你的联系方式，有机会必回信与你共讨${RESET}"
    echo -e "${GREEN}──────────────────────────────────────────${RESET}"
    echo ""
}

# ---------- 自安装逻辑 (核心修复) ----------
install_self() {
    # 如果当前运行的就是全局命令本身，直接跳过
    if [ "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")" = "$CHICK_BIN" ]; then
        return
    fi

    echo -e "${CYAN}>>> 正在将 Chick 脚本安装到系统...${RESET}"
    mkdir -p "$CHICK_HOME"
    
    # 核心修复：抛弃 cp $0，直接从远程仓库拉取完整的自身
    curl -fsSL "$SCRIPT_URL" -o "$CHICK_BIN"
    chmod +x "$CHICK_BIN"
    
    # 注册全局命令 chick
    if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
        sudo ln -sf "$CHICK_BIN" /usr/local/bin/chick
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$CHICK_BIN" "$HOME/.local/bin/chick"
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    echo -e "${GREEN}✅ 安装成功！以后只需在终端输入 ${YELLOW}chick${GREEN} 即可召唤本菜单。${RESET}"
    sleep 1.5
}

# ---------- 检查依赖 ----------
check_dependencies() {
    local missing=()
    for cmd in git curl wget; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}>>> 正在安装必要依赖：${missing[*]}...${RESET}"
        case "$OS_TYPE" in
            termux) pkg install -y "${missing[@]}" ;;
            macos)  brew install "${missing[@]}" 2>/dev/null || true ;;
            *)      sudo apt update -qq && sudo apt install -y "${missing[@]}" ;;
        esac
    fi
}

# ============================================================
#  功能模块
# ============================================================

# ---------- 安装桌面环境 ----------
install_desktop() {
    echo ""
    gum spin --spinner dot --title "正在安装 XFCE 桌面 + VNC (可能需要几分钟)..." -- bash -c "
        sudo apt update -qq
        sudo apt install -y tigervnc-standalone-server xfce4 xfce4-goodies websockify dbus-x11 fonts-noto-cjk
        [ -d \"\$HOME/noVNC\" ] || git clone -q https://github.com/novnc/noVNC.git \"\$HOME/noVNC\"
    "
    set_desktop_installed
    gum style --foreground 82 "✅ 桌面环境安装完成！"
}

# ---------- 启动桌面 ----------
start_desktop() {
    vncserver -kill :1 2>/dev/null || true
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
    vncserver -SecurityType none -xstartup "xfce4-session" :1 -geometry 1280x720 -depth 24
    cd "$HOME/noVNC"
    ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 &
    cd - > /dev/null
    gum style --foreground 82 "✅ 桌面已启动！在 Codespaces 的 Ports 标签页打开 6080 端口即可访问。"
}

# ---------- 停止桌面 ----------
stop_desktop() {
    vncserver -kill :1 2>/dev/null || true
    pkill -f novnc_proxy 2>/dev/null || true
    gum style --foreground 214 "⏹️ 桌面已停止。"
}

# ---------- 安装软件（可选） ----------
install_software() {
    local selected
    selected=$(gum choose --no-limit --height 15 \
        --header "🐤 选择要安装的软件 (空格选择，回车确认)" \
        --cursor "🐤 " \
        "${APP_LIST[@]}")

    [ -z "$selected" ] && return

    while IFS= read -r app; do
        case "$app" in
            "Google Chrome") install_chrome ;;
            "Firefox") install_firefox ;;
            "微信") install_wechat ;;
            "QQ") install_qq ;;
            "Android Studio") install_android_studio ;;
            "VS Code Server") install_vscode_server ;;
            "Docker") install_docker ;;
            "Node.js") install_nodejs ;;
            "Python") install_python ;;
            "中文输入法 (Fcitx5)") install_ime ;;
        esac
    done <<< "$selected"

    gum style --foreground 82 "✅ 所选软件安装完成！"
}

install_chrome() {
    gum spin --title "安装 Chrome..." -- bash -c '
        mkdir -p ~/setup-chrome && cd ~/setup-chrome
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
    '
}
install_firefox() { gum spin --title "安装 Firefox..." -- sudo apt install -y firefox; }
install_wechat() {
    gum spin --title "安装微信 (deepin-wine)..." -- bash -c '
        wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
        sudo apt-get install -y com.qq.weixin.deepin
    '
}
install_qq() {
    gum spin --title "安装 QQ (deepin-wine)..." -- bash -c '
        wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
        sudo apt-get install -y com.qq.im.deepin
    '
}
install_android_studio() {
    gum spin --title "安装 Android Studio..." -- bash -c '
        sudo apt install -y openjdk-17-jdk
        mkdir -p ~/android-studio && cd ~/android-studio
        wget -q https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.1.1.11/android-studio-2024.1.1.11-linux.tar.gz -O as.tar.gz
        tar -xzf as.tar.gz
        echo "export PATH=\$PATH:\$HOME/android-studio/android-studio/bin" >> ~/.bashrc
    '
}
install_vscode_server() {
    gum spin --title "安装 VS Code Server..." -- bash -c '
        wget -qO- https://aka.ms/install-vscode-server/setup.sh | sh
    '
}
install_docker() {
    gum spin --title "安装 Docker..." -- bash -c '
        sudo apt install -y docker.io docker-compose
        sudo systemctl enable docker 2>/dev/null || true
    '
}
install_nodejs() {
    gum spin --title "安装 Node.js..." -- bash -c '
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    '
}
install_python() { gum spin --title "安装 Python..." -- sudo apt install -y python3 python3-pip python3-venv; }
install_ime() { gum spin --title "安装中文输入法..." -- sudo apt install -y fcitx5 fcitx5-chinese-addons; }

# ---------- 主菜单 ----------
main_menu() {
    while true; do
        show_banner
        install_gum

        local desktop_status="未安装"
        is_desktop_installed && desktop_status="已安装 ✅"

        local options=()
        if is_desktop_installed; then
            options+=("▶️ 启动桌面")
            options+=("⏹️ 停止桌面")
        else
            options+=("📦 安装桌面环境")
        fi
        options+=("🧩 安装软件")
        options+=("ℹ️ 状态信息")
        options+=("🚪 退出")

        local choice
        choice=$(gum choose \
            --header "🐤 Chick 菜单 | 桌面状态: $desktop_status" \
            --cursor "🐤 " \
            --height 10 \
            "${options[@]}")

        case "$choice" in
            "📦 安装桌面环境") install_desktop ;;
            "▶️ 启动桌面") start_desktop ;;
            "⏹️ 停止桌面") stop_desktop ;;
            "🧩 安装软件") install_software ;;
            "ℹ️ 状态信息")
                gum style \
                    --border rounded --padding "1 2" \
                    "平台: $OS_TYPE" \
                    "桌面环境: $(is_desktop_installed && echo '已安装' || echo '未安装')" \
                    "联系邮箱: xiaojixingdong@gmail.com"
                ;;
            "🚪 退出")
                gum style --foreground 82 "感谢使用 Chick 脚本！再见 🐤"
                exit 0
                ;;
        esac

        echo ""
        gum confirm "返回主菜单？" || exit 0
    done
}

# ---------- 启动流程 ----------
check_dependencies
install_self
main_menu