#!/usr/bin/env bash
# ============================================================
#  🐤 Chick 自动安装脚本 --1
#  开发者：小鸡行动 (xiaojixingdong)
#  联系邮箱：xiaojixingdong@gmail.com
#  适用平台：Codespaces / Linux / macOS / WSL / Termux
# ============================================================

# ---------- 颜色与样式 ----------
GREEN='\033[92m'; YELLOW='\033[93m'; CYAN='\033[96m'; RED='\033[91m'; RESET='\033[0m'
BOLD='\033[1m'

# ---------- 配置与路径 ----------
CHICK_HOME="$HOME/.chick"
CHICK_BIN="$CHICK_HOME/chick.sh"
STATE_FILE="$CHICK_HOME/state"
SCRIPT_URL="https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh"

# 软件超市列表（支持空格多选）
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
    "系统监控 (btop)"
    "网速监控 (nload)"
    "流量监控 (iftop)"
)

# 初始化状态
mkdir -p "$CHICK_HOME"
[ -f "$STATE_FILE" ] || echo "desktop=false" > "$STATE_FILE"

# ============================================================
#  基础检测模块
# ============================================================
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

is_desktop_installed() { grep -q "^desktop=true" "$STATE_FILE" 2>/dev/null; }
set_desktop_installed() { sed -i 's/^desktop=.*/desktop=true/' "$STATE_FILE"; }

# 核心修复：自安装与全局命令注册
install_self() {
    if [ "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")" = "$CHICK_BIN" ]; then return; fi
    echo -e "${CYAN}>>> 正在将 Chick 脚本安装到系统...${RESET}"
    mkdir -p "$CHICK_HOME"
    # 直接从远程仓库拉取完整的自己，防止复制临时文件导致空文件
    curl -fsSL "$SCRIPT_URL" -o "$CHICK_BIN"
    chmod +x "$CHICK_BIN"
    
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

# 检查并安装依赖
check_dependencies() {
    local missing=()
    for cmd in git curl wget; do
        if ! command -v "$cmd" >/dev/null 2>&1; then missing+=("$cmd"); fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}>>> 正在补齐必要依赖：${missing[*]}...${RESET}"
        case "$OS_TYPE" in
            termux) pkg install -y "${missing[@]}" ;;
            macos)  brew install "${missing[@]}" 2>/dev/null || true ;;
            *)      sudo apt update -qq && sudo apt install -y "${missing[@]}" ;;
        esac
    fi
}

# 安装 gum 精美菜单组件
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

# ============================================================
#  视觉与进度条模块
# ============================================================
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

# 自定义进度下载器（显示百分比、速度、已下载大小、剩余时间）
download_with_progress() {
    local url="$1" output="$2" filename="$3"
    echo -e "${CYAN}>>> 正在下载 $filename...${RESET}"
    # 使用 wget 原生进度条，能完美显示速度、已下载大小、剩余时间
    wget --show-progress -q --progress=bar:force -O "$output" "$url" 2>&1 | \
    while IFS= read -r -d $'\r' line; do
        echo -ne "\r  🐤 $filename: $line"
    done
    echo ""
}

# ============================================================
#  核心功能：桌面环境
# ============================================================
install_desktop() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}  🖥️  安装 XFCE 桌面 + VNC${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    
    if [ "$OS_TYPE" = "termux" ]; then
        pkg update -y && pkg install -y x11-repo tigervnc xfce4 xfce4-goodies
        set_desktop_installed
        echo -e "${GREEN}✅ Termux 桌面环境安装完成！请使用 VNC Viewer 连接 localhost:5901${RESET}"
        return
    fi

    echo -e "${YELLOW}[1/3] 更新软件源...${RESET}"
    sudo apt update

    echo -e "${YELLOW}[2/3] 安装桌面环境 (文件较多，请观看真实进度条)...${RESET}"
    sudo apt install -y tigervnc-standalone-server xfce4 xfce4-goodies websockify dbus-x11 fonts-noto-cjk

    echo -e "${YELLOW}[3/3] 克隆 noVNC...${RESET}"
    [ ! -d "$HOME/noVNC" ] && git clone --progress https://github.com/novnc/noVNC.git "$HOME/noVNC"

    set_desktop_installed
    echo -e "${GREEN}✅ 桌面环境安装完成！${RESET}"
    echo -e "${YELLOW}>>> 温馨提醒：不用时记得停止 Codespaces，以免额度被扣光。${RESET}"
}

start_desktop() {
    echo ""
    echo -e "${CYAN}>>> 正在启动 VNC 服务器...${RESET}"
    vncserver -kill :1 2>/dev/null || true
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
    vncserver -SecurityType none -xstartup "xfce4-session" :1 -geometry 1280x720 -depth 24
    cd "$HOME/noVNC"
    ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 &
    cd - > /dev/null
    echo -e "${GREEN}✅ 桌面已启动！在 Codespaces 的 Ports 标签页打开 6080 端口即可访问。${RESET}"
}

stop_desktop() {
    echo ""
    echo -e "${YELLOW}⏹️ 正在停止桌面...${RESET}"
    vncserver -kill :1 2>/dev/null || true
    pkill -f novnc_proxy 2>/dev/null || true
    echo -e "${GREEN}✅ 桌面已停止。${RESET}"
}

# ============================================================
#  软件超市（支持选择性安装）
# ============================================================
install_software() {
    local selected
    selected=$(gum choose --no-limit --height 15 \
        --header "🐤 选择要安装的软件 (空格键选择，回车键确认)" \
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
            "系统监控 (btop)") install_btop ;;
            "网速监控 (nload)") install_nload ;;
            "流量监控 (iftop)") install_iftop ;;
        esac
    done <<< "$selected"

    echo -e "${GREEN}✅ 所选软件安装完成！${RESET}"
}

install_chrome() {
    echo -e "${CYAN}>>> 安装 Chrome...${RESET}"
    mkdir -p ~/setup-chrome && cd ~/setup-chrome
    download_with_progress "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "chrome.deb" "Chrome"
    sudo apt install -y ./chrome.deb
    cd ~
}
install_firefox() { echo -e "${CYAN}>>> 安装 Firefox...${RESET}"; sudo apt install -y firefox; }
install_wechat() {
    echo -e "${CYAN}>>> 安装微信 (deepin-wine)...${RESET}"
    wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
    sudo apt-get install -y com.qq.weixin.deepin
}
install_qq() {
    echo -e "${CYAN}>>> 安装 QQ (deepin-wine)...${RESET}"
    wget -O- https://deepin-wine.i-m.dev/setup.sh | sh
    sudo apt-get install -y com.qq.im.deepin
}
install_android_studio() {
    echo -e "${CYAN}>>> 安装 Android Studio (文件较大，请观看进度条)...${RESET}"
    sudo apt install -y openjdk-17-jdk
    mkdir -p ~/android-studio && cd ~/android-studio
    download_with_progress "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.1.1.11/android-studio-2024.1.1.11-linux.tar.gz" "as.tar.gz" "Android Studio"
    tar -xzf as.tar.gz
    echo "export PATH=\$PATH:\$HOME/android-studio/android-studio/bin" >> ~/.bashrc
    cd ~
}
install_vscode_server() { echo -e "${CYAN}>>> 安装 VS Code Server...${RESET}"; wget -qO- https://aka.ms/install-vscode-server/setup.sh | sh; }
install_docker() { echo -e "${CYAN}>>> 安装 Docker...${RESET}"; sudo apt install -y docker.io docker-compose; sudo systemctl enable docker 2>/dev/null || true; }
install_nodejs() { echo -e "${CYAN}>>> 安装 Node.js...${RESET}"; curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; sudo apt install -y nodejs; }
install_python() { echo -e "${CYAN}>>> 安装 Python...${RESET}"; sudo apt install -y python3 python3-pip python3-venv; }
install_ime() { echo -e "${CYAN}>>> 安装中文输入法...${RESET}"; sudo apt install -y fcitx5 fcitx5-chinese-addons; }
install_btop() { echo -e "${CYAN}>>> 安装系统监控 btop...${RESET}"; sudo apt install -y btop; }
install_nload() { echo -e "${CYAN}>>> 安装网速监控 nload...${RESET}"; sudo apt install -y nload; }
install_iftop() { echo -e "${CYAN}>>> 安装流量监控 iftop...${RESET}"; sudo apt install -y iftop; }

# ============================================================
#  系统监控中心
# ============================================================
system_monitor_menu() {
    local choice
    choice=$(gum choose --header "🐤 系统监控中心" \
        --cursor "🐤 " \
        "📊 打开 btop (CPU/内存/网络/GPU)" \
        "🌐 打开 nload (实时网速)" \
        "📡 打开 iftop (连接级流量)" \
        "↩️ 返回主菜单")

    case "$choice" in
        "📊 打开 btop (CPU/内存/网络/GPU)")
            command -v btop >/dev/null || install_btop
            btop
            ;;
        "🌐 打开 nload (实时网速)")
            command -v nload >/dev/null || install_nload
            nload
            ;;
        "📡 打开 iftop (连接级流量)")
            command -v iftop >/dev/null || install_iftop
            sudo iftop
            ;;
    esac
}

# ============================================================
#  主菜单与启动流程
# ============================================================
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
        options+=("📊 系统监控中心")
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
            "📊 系统监控中心") system_monitor_menu ;;
            "ℹ️ 状态信息")
                gum style \
                    --border rounded --padding "1 2" \
                    "平台: $OS_TYPE" \
                    "桌面环境: $(is_desktop_installed && echo '已安装' || echo '未安装')" \
                    "联系邮箱: xiaojixingdong@gmail.com"
                ;;
            "🚪 退出")
                echo -e "${GREEN}感谢使用 Chick 脚本！再见 🐤${RESET}"
                exit 0
                ;;
        esac

        echo ""
        gum confirm "返回主菜单？" || exit 0
    done
}

# 启动顺序
check_dependencies
install_self
main_menu