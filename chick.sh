#!/usr/bin/env bash
# ============================================================
#  🐤 Chick 自动安装脚本 --1
#  开发者：小鸡行动 (xiaojixingdong)
#  联系邮箱：xiaojixingdong@gmail.com
#  适用平台：Codespaces / Linux / macOS / WSL / Termux
# ============================================================

# ---------- 颜色与样式 ----------
GREEN='\033[92m'; YELLOW='\033[93m'; CYAN='\033[96m'; RED='\033[91m'; RESET='\033[0m'

# ---------- 配置与路径 ----------
CHICK_HOME="$HOME/.chick"
CHICK_BIN="$CHICK_HOME/chick.sh"
STATE_FILE="$CHICK_HOME/state"
SCRIPT_URL="https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh"

mkdir -p "$CHICK_HOME"
[ -f "$STATE_FILE" ] || echo "desktop=false" > "$STATE_FILE"

# ---------- 状态检测 ----------
is_desktop_installed() { grep -q "^desktop=true" "$STATE_FILE" 2>/dev/null; }
set_desktop_installed() { sed -i 's/^desktop=.*/desktop=true/' "$STATE_FILE"; }

# ---------- 系统检测 ----------
detect_os() {
    if [ -n "${TERMUX_VERSION:-}" ] || [[ "${PREFIX:-}" == *"com.termux"* ]]; then echo "termux"
    elif [ "$(uname -s)" = "Darwin" ]; then echo "macos"
    elif [ -n "${CODESPACES:-}" ]; then echo "codespaces"
    elif grep -qi microsoft /proc/version 2>/dev/null; then echo "wsl"
    else echo "linux"; fi
}
OS_TYPE=$(detect_os)

# ---------- 自安装与全局命令 ----------
install_self() {
    if [ "$(cd "$(dirname "$0")" && pwd)/$(basename "$0")" = "$CHICK_BIN" ]; then return; fi
    echo -e "${CYAN}>>> 正在将 Chick 脚本安装到系统...${RESET}"
    mkdir -p "$CHICK_HOME"
    curl -fsSL "$SCRIPT_URL" -o "$CHICK_BIN"
    chmod +x "$CHICK_BIN"
    if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
        sudo ln -sf "$CHICK_BIN" /usr/local/bin/chick
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$CHICK_BIN" "$HOME/.local/bin/chick"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    echo -e "${GREEN}✅ 安装成功！以后只需在终端输入 ${YELLOW}chick${GREEN} 即可召唤本菜单。${RESET}"
    sleep 1.5
}

# 检查依赖
check_dependencies() {
    local missing=()
    for cmd in git curl wget; do
        if ! command -v "$cmd" >/dev/null 2>&1; then missing+=("$cmd"); fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}>>> 正在补齐必要依赖：${missing[*]}...${RESET}"
        sudo apt update -qq && sudo apt install -y "${missing[@]}"
    fi
}

# ---------- 大字 Banner ----------
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

# ============================================================
#  核心功能模块
# ============================================================
install_desktop() {
    echo ""
    echo -e "${CYAN}>>> 开始安装 XFCE 桌面 + VNC，请耐心等待进度条...${RESET}"
    sudo apt update
    sudo apt install -y tigervnc-standalone-server xfce4 xfce4-goodies websockify dbus-x11 fonts-noto-cjk
    [ ! -d "$HOME/noVNC" ] && git clone --progress https://github.com/novnc/noVNC.git "$HOME/noVNC"
    set_desktop_installed
    echo -e "${GREEN}✅ 桌面环境安装完成！${RESET}"
}

start_desktop() {
    echo ""
    echo -e "${CYAN}>>> 正在启动 VNC...${RESET}"
    vncserver -kill :1 >/dev/null 2>&1 || true
    pkill -f novnc_proxy >/dev/null 2>&1 || true
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 >/dev/null 2>&1 || true
    
    vncserver -SecurityType none -xstartup "xfce4-session" :1 -geometry 1280x720 -depth 24 >/dev/null 2>&1
    if ! pgrep -f "Xtigervnc :1" >/dev/null; then
        echo -e "${RED}❌ VNC 启动失败，请先安装桌面环境。${RESET}"
        return
    fi

    cd "$HOME/noVNC"
    ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 >/dev/null 2>&1 &
    sleep 2
    cd - > /dev/null

    if ! pgrep -f "novnc_proxy" >/dev/null; then
        echo -e "${RED}❌ noVNC 代理启动失败！${RESET}"
        return
    fi

    echo -e "${GREEN}✅ 桌面已启动！${RESET}"
    echo -e "${YELLOW}👉 在底部「端口 / Ports」里找到 6080，把可见性改成「公开 / Public」。${RESET}"
    echo -e "${YELLOW}👉 然后点旁边的🌍地球图标，就能在手机上打开了！${RESET}"
}

stop_desktop() {
    echo ""
    echo -e "${YELLOW}⏹️ 正在停止桌面...${RESET}"
    vncserver -kill :1 2>/dev/null || true
    pkill -f novnc_proxy 2>/dev/null || true
    echo -e "${GREEN}✅ 桌面已停止。${RESET}"
}

# ============================================================
#  🍔 软件超市（纯数字选择，手机绝对能用！）
# ============================================================
install_software() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}  🧩 软件超市（输入数字，按回车确认）${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "  ${YELLOW}1)${RESET} Google Chrome"
    echo -e "  ${YELLOW}2)${RESET} Firefox"
    echo -e "  ${YELLOW}3)${RESET} 微信 (deepin-wine)"
    echo -e "  ${YELLOW}4)${RESET} QQ (deepin-wine)"
    echo -e "  ${YELLOW}5)${RESET} Android Studio"
    echo -e "  ${YELLOW}6)${RESET} VS Code Server"
    echo -e "  ${YELLOW}7)${RESET} Docker"
    echo -e "  ${YELLOW}8)${RESET} Node.js"
    echo -e "  ${YELLOW}9)${RESET} Python"
    echo -e "  ${YELLOW}10)${RESET} 中文输入法"
    echo -e "  ${YELLOW}11)${RESET} 系统监控 (btop)"
    echo -e "  ${YELLOW}12)${RESET} 网速监控 (nload)"
    echo -e "  ${YELLOW}13)${RESET} 流量监控 (iftop)"
    echo ""
    printf "  ${YELLOW}👉 请输入数字（可多选，用空格隔开，例如 1 3 5），然后按回车：${RESET}"
    read -r choices

    [ -z "$choices" ] && return

    for choice in $choices; do
        case "$choice" in
            1) install_chrome ;;
            2) install_firefox ;;
            3) install_wechat ;;
            4) install_qq ;;
            5) install_android_studio ;;
            6) install_vscode_server ;;
            7) install_docker ;;
            8) install_nodejs ;;
            9) install_python ;;
            10) install_ime ;;
            11) install_btop ;;
            12) install_nload ;;
            13) install_iftop ;;
            *) echo -e "${RED}>>> 无效数字：$choice，已跳过。${RESET}" ;;
        esac
    done
    echo -e "${GREEN}✅ 软件安装流程结束！${RESET}"
}

# 下载器（保留原生进度条）
download_with_progress() {
    local url="$1" output="$2" filename="$3"
    echo -e "${CYAN}>>> 正在下载 $filename...${RESET}"
    wget --show-progress -q --progress=bar:force -O "$output" "$url" 2>&1 | while IFS= read -r -d $'\r' line; do echo -ne "\r  🐤 $filename: $line"; done
    echo ""
}

# 具体安装函数
install_chrome() { echo -e "${CYAN}>>> 安装 Chrome...${RESET}"; mkdir -p ~/setup-chrome && cd ~/setup-chrome; download_with_progress "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "chrome.deb" "Chrome"; sudo apt install -y ./chrome.deb; cd ~; }
install_firefox() { echo -e "${CYAN}>>> 安装 Firefox...${RESET}"; sudo apt install -y firefox; }
install_wechat() { echo -e "${CYAN}>>> 安装微信...${RESET}"; wget -O- https://deepin-wine.i-m.dev/setup.sh | sh; sudo apt-get install -y com.qq.weixin.deepin; }
install_qq() { echo -e "${CYAN}>>> 安装 QQ...${RESET}"; wget -O- https://deepin-wine.i-m.dev/setup.sh | sh; sudo apt-get install -y com.qq.im.deepin; }
install_android_studio() { echo -e "${CYAN}>>> 安装 Android Studio (大文件，看进度条)...${RESET}"; sudo apt install -y openjdk-17-jdk; mkdir -p ~/android-studio && cd ~/android-studio; download_with_progress "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.1.1.11/android-studio-2024.1.1.11-linux.tar.gz" "as.tar.gz" "Android Studio"; tar -xzf as.tar.gz; echo "export PATH=\$PATH:\$HOME/android-studio/android-studio/bin" >> ~/.bashrc; cd ~; }
install_vscode_server() { echo -e "${CYAN}>>> 安装 VS Code Server...${RESET}"; wget -qO- https://aka.ms/install-vscode-server/setup.sh | sh; }
install_docker() { echo -e "${CYAN}>>> 安装 Docker...${RESET}"; sudo apt install -y docker.io docker-compose; sudo systemctl enable docker 2>/dev/null || true; }
install_nodejs() { echo -e "${CYAN}>>> 安装 Node.js...${RESET}"; curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; sudo apt install -y nodejs; }
install_python() { echo -e "${CYAN}>>> 安装 Python...${RESET}"; sudo apt install -y python3 python3-pip python3-venv; }
install_ime() { echo -e "${CYAN}>>> 安装中文输入法...${RESET}"; sudo apt install -y fcitx5 fcitx5-chinese-addons; }
install_btop() { echo -e "${CYAN}>>> 安装 btop...${RESET}"; sudo apt install -y btop; }
install_nload() { echo -e "${CYAN}>>> 安装 nload...${RESET}"; sudo apt install -y nload; }
install_iftop() { echo -e "${CYAN}>>> 安装 iftop...${RESET}"; sudo apt install -y iftop; }

# ============================================================
#  📊 系统监控中心（纯数字选择）
# ============================================================
system_monitor_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}  📊 系统监控中心（输入数字，按回车）${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "  ${YELLOW}1)${RESET} 打开 btop (CPU/内存/网络)"
    echo -e "  ${YELLOW}2)${RESET} 打开 nload (实时网速)"
    echo -e "  ${YELLOW}3)${RESET} 打开 iftop (连接流量)"
    echo -e "  ${YELLOW}4)${RESET} 返回主菜单"
    echo ""
    printf "  ${YELLOW}👉 请输入数字，按回车：${RESET}"
    read -r choice

    case "$choice" in
        1) command -v btop >/dev/null || install_btop; btop ;;
        2) command -v nload >/dev/null || install_nload; nload ;;
        3) command -v iftop >/dev/null || install_iftop; sudo iftop ;;
        4) return ;;
        *) echo -e "${RED}>>> 无效选择，已跳过。${RESET}" ;;
    esac
}

# ============================================================
#  🐤 主菜单（纯数字选择，最适合手机！）
# ============================================================
main_menu() {
    while true; do
        show_banner
        
        local desktop_status="未安装"
        is_desktop_installed && desktop_status="已安装 ✅"

        echo -e "${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${CYAN}  🐤 Chick 主菜单 | 桌面状态: $desktop_status${RESET}"
        echo -e "${CYAN}═══════════════════════════════════════${RESET}"
        
        if is_desktop_installed; then
            echo -e "  ${YELLOW}1)${RESET} ▶️ 启动桌面"
            echo -e "  ${YELLOW}2)${RESET} ⏹️ 停止桌面"
        else
            echo -e "  ${YELLOW}1)${RESET} 📦 安装桌面环境"
        fi
        echo -e "  ${YELLOW}3)${RESET} 🧩 安装软件"
        echo -e "  ${YELLOW}4)${RESET} 📊 系统监控中心"
        echo -e "  ${YELLOW}5)${RESET} ℹ️ 状态信息"
        echo -e "  ${YELLOW}6)${RESET} 🚪 退出"
        echo ""
        printf "  ${YELLOW}👉 请输入数字（按回车确认）：${RESET}"
        read -r choice

        if is_desktop_installed; then
            case "$choice" in
                1) start_desktop ;;
                2) stop_desktop ;;
                3) install_software ;;
                4) system_monitor_menu ;;
                5) echo -e "${CYAN}平台: $OS_TYPE | 桌面: 已安装${RESET}" ;;
                6) echo -e "${GREEN}感谢使用 Chick 脚本！再见 🐤${RESET}"; exit 0 ;;
                *) echo -e "${RED}>>> 无效数字，请重新输入。${RESET}" ;;
            esac
        else
            case "$choice" in
                1) install_desktop ;;
                3) install_software ;;
                4) system_monitor_menu ;;
                5) echo -e "${CYAN}平台: $OS_TYPE | 桌面: 未安装${RESET}" ;;
                6) echo -e "${GREEN}感谢使用 Chick 脚本！再见 🐤${RESET}"; exit 0 ;;
                *) echo -e "${RED}>>> 无效数字，请重新输入。${RESET}" ;;
            esac
        fi

        echo ""
        printf "  ${CYAN}按回车键返回主菜单...${RESET}"
        read -r
    done
}

# 启动顺序
check_dependencies
install_self
main_menu