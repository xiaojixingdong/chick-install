#!/usr/bin/env bash
# ============================================================
#  🐤 Chick 自动安装脚本 -- v2.1 (Fixed)
#  开发者：小鸡行动 (xiaojixingdong)
#  联系邮箱：xiaojixingdong@gmail.com
#  适用平台：Codespaces / Linux / WSL  —— 主力支持
#            macOS / Termux            —— 实验性支持
# ============================================================

set -uo pipefail

# ---------- 颜色 ----------
GREEN='\033[92m'; YELLOW='\033[93m'; CYAN='\033[96m'; RED='\033[91m'; RESET='\033[0m'

# ---------- 配置 ----------
CHICK_HOME="$HOME/.chick"
CHICK_BIN="$CHICK_HOME/chick.sh"
STATE_FILE="$CHICK_HOME/state"
SCRIPT_URL="https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh"

CURRENT_DE="xfce"

mkdir -p "$CHICK_HOME"
[ -f "$STATE_FILE" ] || printf 'desktop=false\nde=xfce\n' > "$STATE_FILE"

# ============================================================
#  系统检测
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

# ---------- 跨平台 readlink -f ----------
realpath_portable() {
    local p="$1"
    [ -z "$p" ] && return 1
    local out
    if out=$(readlink -f "$p" 2>/dev/null) && [ -n "$out" ]; then
        echo "$out"; return 0
    fi
    if command -v greadlink >/dev/null 2>&1; then
        out=$(greadlink -f "$p" 2>/dev/null) && [ -n "$out" ] && { echo "$out"; return 0; }
    fi
    if out=$(realpath "$p" 2>/dev/null) && [ -n "$out" ]; then
        echo "$out"; return 0
    fi
    case "$p" in
        /*) echo "$p" ;;
        *)  echo "$(cd "$(dirname "$p")" 2>/dev/null && pwd)/$(basename "$p")" ;;
    esac
}

# ---------- 纯数字校验 ----------
is_uint() {
    [[ "${1:-}" =~ ^[0-9]+$ ]]
}

# ============================================================
#  状态文件（原子重写）
# ============================================================
is_desktop_installed() {
    grep -q "^desktop=true" "$STATE_FILE" 2>/dev/null
}

get_saved_de() {
    grep "^de=" "$STATE_FILE" 2>/dev/null | head -1 | cut -d= -f2
}

write_state() {
    local desktop="$1" de="$2"
    local tmp="$STATE_FILE.tmp.$$"
    {
        echo "desktop=$desktop"
        echo "de=$de"
    } > "$tmp"
    mv -f "$tmp" "$STATE_FILE"
}

set_desktop_installed() {
    write_state "true" "$CURRENT_DE"
}

# ============================================================
#  安全 read（printf -v，无 eval）
# ============================================================
safe_read() {
    local __var="$1"
    local __val=""
    if ! IFS= read -r __val; then
        printf -v "$__var" '%s' ""
        return 1
    fi
    printf -v "$__var" '%s' "$__val"
    return 0
}

# ============================================================
#  自安装
# ============================================================
install_self() {
    local self_path="${BASH_SOURCE[0]:-}"
    local real_self real_chick
    real_self=$(realpath_portable "$self_path" 2>/dev/null || echo "")
    real_chick=$(realpath_portable "$CHICK_BIN" 2>/dev/null || echo "$CHICK_BIN")

    if [ -n "$real_self" ] && [ "$real_self" = "$real_chick" ]; then
        return 0
    fi

    echo -e "${CYAN}>>> 正在将 Chick 脚本安装到系统...${RESET}"
    mkdir -p "$CHICK_HOME"

    local copied=false
    if [ -n "$real_self" ] && [ -f "$real_self" ]; then
        if cp -f "$real_self" "$CHICK_BIN" 2>/dev/null; then
            copied=true
            echo -e "${GREEN}>>> 已从本地复制。${RESET}"
        fi
    fi

    if ! $copied; then
        echo -e "${YELLOW}>>> 正在从远程下载完整脚本...${RESET}"
        if ! curl -fsSL --retry 3 --connect-timeout 15 "$SCRIPT_URL" -o "$CHICK_BIN"; then
            echo -e "${RED}❌ 下载失败，请检查网络连接。${RESET}"
            return 1
        fi
    fi
    chmod +x "$CHICK_BIN"

    local bin_dir="/usr/local/bin"
    local use_sudo=false
    if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        use_sudo=true
    fi

    if $use_sudo; then
        sudo ln -sf "$CHICK_BIN" "$bin_dir/chick" 2>/dev/null || true
    else
        bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        ln -sf "$CHICK_BIN" "$bin_dir/chick"
    fi

    local path_line="export PATH=\"$bin_dir:\$PATH\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        grep -qF "export PATH=\"$bin_dir" "$rc" 2>/dev/null || \
            printf '%s\n' "$path_line" >> "$rc" 2>/dev/null || true
    done
    export PATH="$bin_dir:$PATH"

    echo -e "${GREEN}✅ 安装成功！以后只需在终端输入 ${YELLOW}chick${GREEN} 即可召唤本菜单。${RESET}"
    sleep 1.2
    return 0
}

# ============================================================
#  依赖检查
# ============================================================
check_dependencies() {
    local deps=()
    case "$OS_TYPE" in
        termux) deps=(git curl wget) ;;
        macos)  deps=(git curl wget) ;;
        *)      deps=(git curl wget sudo) ;;
    esac

    local missing=()
    local cmd
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    [ ${#missing[@]} -eq 0 ] && return 0

    echo -e "${YELLOW}>>> 正在安装必要依赖：${missing[*]} ...${RESET}"
    case "$OS_TYPE" in
        termux) pkg install -y "${missing[@]}" 2>/dev/null || true ;;
        macos)  brew install "${missing[@]}" 2>/dev/null || true ;;
        *)      sudo apt update -qq && sudo apt install -y "${missing[@]}" 2>/dev/null || true ;;
    esac
}

# ============================================================
#  Banner
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
    echo -e "${GREEN}──────────────────────────────────────────${RESET}"
    echo ""
}

# ============================================================
#  语言设置
# ============================================================
set_language_chinese() {
    case "$OS_TYPE" in
        termux|macos)
            echo -e "${YELLOW}>>> 当前平台无需设置系统语言。${RESET}"
            return 0 ;;
    esac

    if ! command -v locale-gen >/dev/null 2>&1 && ! command -v debconf-set-selections >/dev/null 2>&1; then
        echo -e "${YELLOW}>>> 当前系统不是 Debian/Ubuntu 系，跳过。${RESET}"
        return 0
    fi

    echo -e "${CYAN}>>> 正在设置系统语言为简体中文...${RESET}"
    export DEBIAN_FRONTEND=noninteractive
    sudo debconf-set-selections <<'EOF' 2>/dev/null || true
debconf debconf/frontend select Noninteractive
locales locales/locales_to_be_generated multiselect zh_CN.UTF-8 UTF-8
locales locales/default_environment_locale select zh_CN.UTF-8
tzdata tzdata/Areas select Asia
tzdata tzdata/Zones/Asia select Shanghai
EOF
    sudo apt install -y locales 2>/dev/null || true
    sudo locale-gen zh_CN.UTF-8 2>/dev/null || true
    sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8 2>/dev/null || true
    echo -e "${GREEN}✅ 语言已设置为简体中文（重新登录后生效）。${RESET}"
}

# ============================================================
#  桌面环境选择
# ============================================================
choose_distro_and_de() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}  🐧 选择桌面环境${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo ""

    local options=()
    case "$OS_TYPE" in
        termux)
            options=("xfce" "lxqt")
            echo -e "  ${YELLOW}1)${RESET} XFCE (轻量，实验性支持)"
            echo -e "  ${YELLOW}2)${RESET} LXQt (极轻量，实验性支持)"
            ;;
        macos)
            options=("macos" "xpra")
            echo -e "  ${YELLOW}1)${RESET} 使用 macOS 内置桌面 (VNC 连接)"
            echo -e "  ${YELLOW}2)${RESET} Xpra (轻量，推荐)"
            ;;
        *)
            options=("xfce" "kde" "lxqt")
            echo -e "  ${YELLOW}1)${RESET} XFCE (轻量推荐，约 734 MB)"
            echo -e "  ${YELLOW}2)${RESET} KDE Plasma (华丽，约 1.5 GB)"
            echo -e "  ${YELLOW}3)${RESET} LXQt (极轻量，约 500 MB)"
            ;;
    esac
    echo ""
    printf "  ${YELLOW}👉 请输入数字：${RESET}"
    safe_read de_choice || de_choice="1"

    # 纯数字校验，非数字回退到 1
    local idx=0
    if is_uint "${de_choice:-}"; then
        idx=$(( de_choice - 1 ))
    else
        if [ -n "${de_choice:-}" ]; then
            echo -e "${YELLOW}>>> 「$de_choice」不是有效数字，使用默认选项。${RESET}"
        fi
        idx=0
    fi

    if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#options[@]} ]; then
        echo -e "${YELLOW}>>> 超出范围，使用默认选项。${RESET}"
        idx=0
    fi

    CURRENT_DE="${options[$idx]}"
    echo -e "${GREEN}✅ 已选择：$CURRENT_DE${RESET}"
    sleep 1
}

# ============================================================
#  桌面环境安装
# ============================================================
install_desktop() {
    echo ""
    echo -e "${CYAN}>>> 安装 $CURRENT_DE 桌面环境...${RESET}"

    local ok=true
    case "$OS_TYPE" in
        termux)
            echo -e "${YELLOW}>>> [实验性] Termux 桌面依赖 Termux:X11，成功率不保证。${RESET}"
            pkg update -y 2>/dev/null || true
            pkg install -y x11-repo 2>/dev/null || true
            pkg install -y termux-x11-nightly xorg-xrandr dbus 2>/dev/null || ok=false
            ;;

        macos)
            if [ "$CURRENT_DE" = "xpra" ]; then
                brew install xpra 2>/dev/null || true
            fi
            ;;

        *)
            sudo apt update || ok=false
            case "$CURRENT_DE" in
                xfce) sudo apt install -y xfce4 xfce4-goodies || ok=false ;;
                kde)  sudo apt install -y kde-plasma-desktop || ok=false ;;
                lxqt) sudo apt install -y lxqt-core || ok=false ;;
            esac
            sudo apt install -y tigervnc-standalone-server websockify dbus-x11 fonts-noto-cjk || ok=false

            if [ ! -d "$HOME/noVNC/.git" ]; then
                rm -rf "$HOME/noVNC"
                git clone --depth=1 https://github.com/novnc/noVNC.git "$HOME/noVNC" || ok=false
            fi
            ;;
    esac

    if $ok; then
        set_desktop_installed
        echo -e "${GREEN}✅ 桌面环境安装完成！${RESET}"
        echo -e "${YELLOW}>>> 回到主菜单选择「启动桌面」。${RESET}"
    else
        echo -e "${RED}❌ 安装过程中出现错误，未写入安装状态。${RESET}"
    fi
}

# ============================================================
#  DE → 启动命令映射
# ============================================================
resolve_de_startup() {
    local de="$1"
    local candidates=()
    case "$de" in
        xfce) candidates=(startxfce4 xfce4-session) ;;
        kde)  candidates=(startplasma-x11 startkde) ;;
        lxqt) candidates=(startlxqt lxqt-session) ;;
        *)    candidates=(startxfce4 xfce4-session) ;;
    esac
    local c p
    for c in "${candidates[@]}"; do
        p=$(command -v "$c" 2>/dev/null) && [ -n "$p" ] && { echo "$p"; return 0; }
    done
    return 1
}

# ============================================================
#  启动 / 停止桌面
# ============================================================
start_desktop() {
    echo ""
    echo -e "${CYAN}>>> 正在启动桌面...${RESET}"

    local saved_de
    saved_de=$(get_saved_de)
    [ -n "$saved_de" ] && CURRENT_DE="$saved_de"

    case "$OS_TYPE" in
        macos)
            if [ "$CURRENT_DE" = "xpra" ]; then
                pgrep -f "xpra" >/dev/null 2>&1 || xpra start :100 --daemon=yes 2>/dev/null || true
                echo -e "${GREEN}✅ Xpra 已启动，连接方式：xpra attach :100${RESET}"
            else
                echo -e "${YELLOW}>>> 请在 系统设置 → 共享 → 屏幕共享 中启用 VNC。${RESET}"
            fi
            return ;;
        termux)
            echo -e "${YELLOW}>>> [实验性] 请在 Termux:X11 App 中手动启动桌面。${RESET}"
            return ;;
    esac

    if ! command -v vncserver >/dev/null 2>&1; then
        echo -e "${RED}❌ 未找到 vncserver，请先安装桌面环境。${RESET}"
        return 1
    fi

    vncserver -kill :1 >/dev/null 2>&1 || true
    pkill -f novnc_proxy >/dev/null 2>&1 || true
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 "$HOME"/.vnc/*.pid 2>/dev/null || true

    local startup_cmd
    if ! startup_cmd=$(resolve_de_startup "$CURRENT_DE"); then
        echo -e "${RED}❌ 找不到 $CURRENT_DE 的启动命令，请确认桌面是否安装成功。${RESET}"
        return 1
    fi

    vncserver :1 -geometry 1280x720 -depth 24 \
        -xstartup "$startup_cmd" \
        -SecurityTypes None >/dev/null 2>&1

    if ! pgrep -f "Xtigervnc :1|Xvnc :1" >/dev/null 2>&1; then
        echo -e "${RED}❌ VNC 启动失败。${RESET}"
        echo -e "${YELLOW}>>> 手动清理：rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 ~/.vnc/*.pid${RESET}"
        return 1
    fi

    if [ -x "$HOME/noVNC/utils/novnc_proxy" ]; then
        echo -e "${CYAN}>>> 正在启动 noVNC 网页代理...${RESET}"
        # nohup 防止终端关闭时被 SIGHUP 带走；disown 在子 shell 内可能无 job，加 2>/dev/null
        ( cd "$HOME/noVNC" && nohup ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 >/dev/null 2>&1 & disown 2>/dev/null )
        sleep 2
        if pgrep -f novnc_proxy >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 桌面已启动！${RESET}"
            echo -e "${YELLOW}👉 在 Ports 面板把 6080 设为 Public，然后点 🌍 打开。${RESET}"
        else
            echo -e "${YELLOW}⚠️  noVNC 未启动成功，但 VNC 已在 5901 监听。${RESET}"
        fi
    else
        echo -e "${YELLOW}⚠️  未找到 noVNC，VNC 已在 5901 监听。${RESET}"
    fi
}

stop_desktop() {
    echo ""
    echo -e "${YELLOW}⏹️ 正在停止桌面...${RESET}"
    vncserver -kill :1 2>/dev/null || true
    pkill -f novnc_proxy 2>/dev/null || true
    pkill -f xpra 2>/dev/null || true
    pkill -f termux-x11 2>/dev/null || true
    echo -e "${GREEN}✅ 桌面已停止。${RESET}"
}

# ============================================================
#  软件超市
# ============================================================
install_software() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}  🧩 软件超市（输入数字，可多选，空格隔开）${RESET}"
    echo -e "${CYAN}═══════════════════════════════════════${RESET}"

    local software_list=()
    case "$OS_TYPE" in
        termux)
            software_list=("Firefox" "Python" "Node.js" "Git" "btop" "nload" "iftop")
            ;;
        macos)
            software_list=("Google Chrome" "Firefox" "VS Code" "Python" "Node.js" "Docker" "btop")
            ;;
        *)
            software_list=("Google Chrome" "Firefox" "微信" "QQ" "Android Studio" "VS Code Server" "Docker" "Node.js" "Python" "中文输入法" "btop" "nload" "iftop")
            ;;
    esac

    local i=1
    for app in "${software_list[@]}"; do
        echo -e "  ${YELLOW}$i)${RESET} $app"
        ((i++)) || true
    done
    echo ""
    printf "  ${YELLOW}👉 请输入数字（例如 1 3 5），回车确认：${RESET}"
    safe_read choices || return 0
    [ -z "$choices" ] && return 0

    local choice
    for choice in $choices; do
        if ! is_uint "$choice"; then
            echo -e "${RED}>>> 无效输入：$choice，已跳过。${RESET}"
            continue
        fi
        local idx=$((choice - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#software_list[@]} ]; then
            install_single_app "${software_list[$idx]}" || true
        else
            echo -e "${RED}>>> 超出范围：$choice，已跳过。${RESET}"
        fi
    done
    echo -e "${GREEN}✅ 软件安装流程结束！${RESET}"
}

install_single_app() {
    local app="$1"
    echo -e "${CYAN}>>> 安装 $app...${RESET}"
    case "$app" in
        "Google Chrome")
            case "$OS_TYPE" in
                macos) brew install --cask google-chrome 2>/dev/null || true ;;
                *)
                    local arch
                    arch=$(uname -m)
                    if [ "$arch" != "x86_64" ]; then
                        echo -e "${RED}>>> 当前架构 $arch 无官方 Chrome deb 包，跳过。${RESET}"
                        return 1
                    fi
                    mkdir -p "$HOME/setup-chrome" && cd "$HOME/setup-chrome"
                    if wget -q --show-progress -O chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
                        && [ -s chrome.deb ]; then
                        sudo apt install -y ./chrome.deb
                    else
                        echo -e "${RED}>>> Chrome 下载失败。${RESET}"
                    fi
                    cd "$HOME"
                    ;;
            esac
            ;;
        "Firefox")
            case "$OS_TYPE" in
                termux) echo -e "${YELLOW}>>> Termux 无官方 Firefox 包，跳过。${RESET}" ;;
                macos)  brew install --cask firefox 2>/dev/null || true ;;
                *)      sudo apt install -y firefox || true ;;
            esac
            ;;
        "微信")
            if [[ "$OS_TYPE" != "macos" && "$OS_TYPE" != "termux" ]]; then
                wget -O- https://deepin-wine.i-m.dev/setup.sh | sh || true
                sudo apt-get install -y com.qq.weixin.deepin || true
            fi
            ;;
        "QQ")
            if [[ "$OS_TYPE" != "macos" && "$OS_TYPE" != "termux" ]]; then
                wget -O- https://deepin-wine.i-m.dev/setup.sh | sh || true
                sudo apt-get install -y com.qq.im.deepin || true
            fi
            ;;
        "Android Studio")
            if [[ "$OS_TYPE" == "macos" ]]; then
                brew install --cask android-studio 2>/dev/null || true
            elif [[ "$OS_TYPE" != "termux" ]]; then
                install_android_studio || true
            fi
            ;;
        "VS Code"|"VS Code Server")
            case "$OS_TYPE" in
                macos) brew install --cask visual-studio-code 2>/dev/null || true ;;
                termux) pkg install -y code-server 2>/dev/null || true ;;
                *) wget -qO- https://aka.ms/install-vscode-server/setup.sh | sh || true ;;
            esac
            ;;
        "Docker")
            case "$OS_TYPE" in
                macos) brew install --cask docker 2>/dev/null || true ;;
                termux) echo -e "${YELLOW}>>> Termux 请使用 proot-distro 运行 Docker。${RESET}" ;;
                *) install_docker ;;
            esac
            ;;
        "Node.js")
            case "$OS_TYPE" in
                termux) pkg install -y nodejs 2>/dev/null || true ;;
                macos)  brew install node 2>/dev/null || true ;;
                *) curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install -y nodejs || true ;;
            esac
            ;;
        "Python")
            case "$OS_TYPE" in
                termux) pkg install -y python 2>/dev/null || true ;;
                macos)  brew install python 2>/dev/null || true ;;
                *) sudo apt install -y python3 python3-pip python3-venv || true ;;
            esac
            ;;
        "Git")
            case "$OS_TYPE" in
                termux) pkg install -y git 2>/dev/null || true ;;
                macos)  brew install git 2>/dev/null || true ;;
                *) sudo apt install -y git || true ;;
            esac
            ;;
        "中文输入法")
            case "$OS_TYPE" in
                termux) echo -e "${YELLOW}>>> Termux 输入法请使用 Termux 内置方案。${RESET}" ;;
                macos)  echo -e "${YELLOW}>>> macOS 请使用系统自带输入法。${RESET}" ;;
                *) sudo apt install -y fcitx5 fcitx5-chinese-addons || true ;;
            esac
            ;;
        "btop")
            case "$OS_TYPE" in
                macos) brew install btop 2>/dev/null || true ;;
                termux) pkg install -y btop 2>/dev/null || true ;;
                *) sudo apt install -y btop || true ;;
            esac
            ;;
        "nload")
            case "$OS_TYPE" in
                macos) brew install nload 2>/dev/null || true ;;
                termux) pkg install -y nload 2>/dev/null || true ;;
                *) sudo apt install -y nload || true ;;
            esac
            ;;
        "iftop")
            case "$OS_TYPE" in
                macos) brew install iftop 2>/dev/null || true ;;
                termux) pkg install -y iftop 2>/dev/null || true ;;
                *) sudo apt install -y iftop || true ;;
            esac
            ;;
    esac
}

install_android_studio() {
    echo -e "${CYAN}>>> 安装 Android Studio...${RESET}"
    local arch
    arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        echo -e "${RED}>>> 当前架构 $arch 无官方包，跳过。${RESET}"
        return 1
    fi
    sudo apt install -y openjdk-17-jdk || true

    # 上线前请替换为当时的最新稳定版本号
    local version="2024.2.1.12"
    local url="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${version}/android-studio-${version}-linux.tar.gz"

    mkdir -p "$HOME/android-studio" && cd "$HOME/android-studio"
    if ! wget -q --show-progress -O as.tar.gz "$url" || [ ! -s as.tar.gz ]; then
        echo -e "${RED}❌ 下载失败，请检查版本号或网络。${RESET}"
        cd "$HOME"; return 1
    fi
    if ! tar -xzf as.tar.gz; then
        echo -e "${RED}❌ 解压失败，文件可能不完整。${RESET}"
        rm -f as.tar.gz
        cd "$HOME"; return 1
    fi
    local path_line="export PATH=\"\$PATH:\$HOME/android-studio/android-studio/bin\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        grep -qF "android-studio/bin" "$rc" 2>/dev/null || printf '%s\n' "$path_line" >> "$rc"
    done
    echo -e "${GREEN}✅ Android Studio 安装完成，运行 studio.sh 启动。${RESET}"
    cd "$HOME"
}

# ============================================================
#  Docker
# ============================================================
install_docker() {
    echo -e "${CYAN}>>> 安装 Docker...${RESET}"
    sudo apt install -y docker.io docker-compose 2>/dev/null || true

    if sudo docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker 已在运行。${RESET}"
        return 0
    fi

    echo -e "${CYAN}>>> 正在尝试启动 Docker 守护进程...${RESET}"
    ( sudo service docker start >/dev/null 2>&1 || sudo dockerd >/tmp/dockerd.log 2>&1 ) &
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sudo docker info >/dev/null 2>&1 && break
        sleep 2
    done

    if sudo docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker 安装完成并已启动。${RESET}"
    else
        echo -e "${YELLOW}>>> Docker 已安装，但守护进程未就绪。${RESET}"
        echo -e "${YELLOW}>>> 请手动运行：sudo dockerd >/tmp/dockerd.log 2>&1 &${RESET}"
    fi
}

# ============================================================
#  Windows 容器
# ============================================================
install_windows_container() {
    if [[ "$OS_TYPE" == "macos" || "$OS_TYPE" == "termux" ]]; then
        echo -e "${YELLOW}>>> 当前平台不支持 Windows 容器。${RESET}"
        return 0
    fi

    echo -e "${RED}═══════════════════════════════════════${RESET}"
    echo -e "${RED}  ⚠️  高风险操作警告${RESET}"
    echo -e "${RED}═══════════════════════════════════════${RESET}"
    echo -e "${YELLOW}>>> 需要 KVM 硬件加速，占用大量磁盘（≥64 GB）。${RESET}"
    echo ""
    printf "  ${RED}👉 确定要继续吗？输入 YES 确认：${RESET}"
    safe_read confirm || return 0
    [ "$confirm" != "YES" ] && return 0

    local avail_kb
    avail_kb=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
    if [ -n "$avail_kb" ] && [ "$avail_kb" -lt $((20 * 1024 * 1024)) ]; then
        echo -e "${RED}❌ 可用磁盘不足 20 GB，取消安装。${RESET}"
        return 1
    fi

    echo -e "  ${YELLOW}1)${RESET} Windows 11  ${YELLOW}2)${RESET} Windows 10  ${YELLOW}3)${RESET} Windows 7  ${YELLOW}4)${RESET} Windows XP"
    printf "  ${YELLOW}👉 请选择版本：${RESET}"
    safe_read win_choice || win_choice="1"
    local WIN_VERSION
    case "$win_choice" in
        1) WIN_VERSION="11" ;;
        2) WIN_VERSION="10" ;;
        3) WIN_VERSION="7u" ;;
        4) WIN_VERSION="xp" ;;
        *) WIN_VERSION="11" ;;
    esac

    local KVM_OK=false
    if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        KVM_OK=true
        echo -e "${GREEN}✅ 检测到可用的 /dev/kvm。${RESET}"
    else
        echo -e "${RED}⚠️  未检测到可用的 KVM，性能会非常差。${RESET}"
        printf "  ${RED}👉 仍要继续？输入 YES：${RESET}"
        safe_read kvm_ok || return 0
        [ "$kvm_ok" != "YES" ] && return 0
    fi

    install_docker

    if sudo docker ps -a --format '{{.Names}}' | grep -qx "windows"; then
        echo -e "${YELLOW}>>> 发现同名旧容器，正在移除...${RESET}"
        sudo docker rm -f windows >/dev/null 2>&1 || true
    fi

    echo -e "${CYAN}>>> 拉取镜像 dockurr/windows:latest ...${RESET}"
    if ! sudo docker pull dockurr/windows:latest; then
        echo -e "${RED}❌ 镜像拉取失败。${RESET}"
        return 1
    fi

    local docker_cmd=(
        sudo docker run -d --name windows
        --cap-add=NET_ADMIN
        -p 8006:8006 -p 3389:3389/tcp -p 3389:3389/udp
        -e "VERSION=$WIN_VERSION"
        -e "RAM_SIZE=4G" -e "CPU_CORES=2" -e "DISK_SIZE=64G"
        -v "$HOME/windows:/storage"
        --stop-timeout 120 --restart on-failure
    )
    if [ -e /dev/net/tun ]; then
        docker_cmd+=(--device=/dev/net/tun)
    fi
    if $KVM_OK; then
        docker_cmd+=(--device=/dev/kvm)
    else
        docker_cmd+=(-e "KVM=N")
    fi
    docker_cmd+=(dockurr/windows:latest)

    if "${docker_cmd[@]}"; then
        echo -e "${GREEN}✅ Windows 容器已启动！在 Ports 面板打开 8006 端口访问。${RESET}"
    else
        echo -e "${RED}❌ 容器启动失败，请查看上方错误信息。${RESET}"
    fi
}

# ============================================================
#  容器工具入口
# ============================================================
install_container_tools() {
    case "$OS_TYPE" in
        macos)
            brew install --cask docker 2>/dev/null || true
            echo -e "${GREEN}✅ Docker Desktop 安装完成。${RESET}"
            ;;
        termux)
            echo -e "${YELLOW}>>> Termux 请使用 proot-distro 安装 Docker。${RESET}"
            ;;
        *)
            install_docker
            ;;
    esac
}

# ============================================================
#  系统监控
# ============================================================
system_monitor_menu() {
    echo ""
    echo -e "${CYAN}  📊 系统监控中心${RESET}"
    echo -e "  ${YELLOW}1)${RESET} btop (CPU/内存/网络)"
    echo -e "  ${YELLOW}2)${RESET} nload (实时网速)"
    echo -e "  ${YELLOW}3)${RESET} iftop (连接流量)"
    echo -e "  ${YELLOW}4)${RESET} 返回主菜单"
    printf "  ${YELLOW}👉 请输入数字：${RESET}"
    safe_read choice || return 0

    case "$choice" in
        1) command -v btop >/dev/null 2>&1 || install_single_app "btop"
           command -v btop >/dev/null 2>&1 && btop ;;
        2) command -v nload >/dev/null 2>&1 || install_single_app "nload"
           command -v nload >/dev/null 2>&1 && nload ;;
        3) command -v iftop >/dev/null 2>&1 || install_single_app "iftop"
           command -v iftop >/dev/null 2>&1 && sudo iftop ;;
        4) return 0 ;;
        *) echo -e "${RED}>>> 无效选择。${RESET}" ;;
    esac
}

# ============================================================
#  主菜单
# ============================================================
main_menu() {
    while true; do
        show_banner
        local status_text="未安装"
        is_desktop_installed && status_text="已安装 ✅"

        echo -e "${CYAN}  🐤 Chick 主菜单 | 平台: $OS_TYPE | 桌面: $status_text${RESET}"
        echo -e "${CYAN}═══════════════════════════════════════${RESET}"

        if is_desktop_installed; then
            echo -e "  ${YELLOW}1)${RESET} ▶️  启动桌面"
            echo -e "  ${YELLOW}2)${RESET} ⏹️  停止桌面"
            echo -e "  ${YELLOW}3)${RESET} 🔄 重新安装/更换桌面"
        else
            echo -e "  ${YELLOW}1)${RESET} 📦 安装桌面环境"
        fi
        echo -e "  ${YELLOW}4)${RESET} 🧩 安装软件"
        echo -e "  ${YELLOW}5)${RESET} 🪟 安装 Windows 容器（高风险）"
        echo -e "  ${YELLOW}6)${RESET} 📦 安装容器工具"
        echo -e "  ${YELLOW}7)${RESET} 📊 系统监控中心"
        echo -e "  ${YELLOW}8)${RESET} 🌐 设置系统语言为中文"
        echo -e "  ${YELLOW}9)${RESET} ℹ️  状态信息"
        echo -e "  ${YELLOW}0)${RESET} 🚪 退出"
        printf "  ${YELLOW}👉 请输入数字：${RESET}"

        if ! safe_read choice; then
            echo ""
            echo -e "${YELLOW}>>> 检测到非交互环境，退出。${RESET}"
            exit 0
        fi

        if is_desktop_installed; then
            case "$choice" in
                1) start_desktop ;;
                2) stop_desktop ;;
                3) choose_distro_and_de; install_desktop ;;
                4) install_software ;;
                5) install_windows_container ;;
                6) install_container_tools ;;
                7) system_monitor_menu ;;
                8) set_language_chinese ;;
                9) echo -e "${CYAN}平台: $OS_TYPE | 桌面: $CURRENT_DE${RESET}" ;;
                0) echo -e "${GREEN}感谢使用 Chick 脚本！再见 🐤${RESET}"; exit 0 ;;
                *) echo -e "${RED}>>> 无效数字。${RESET}" ;;
            esac
        else
            case "$choice" in
                1) choose_distro_and_de; install_desktop ;;
                4) install_software ;;
                5) install_windows_container ;;
                6) install_container_tools ;;
                7) system_monitor_menu ;;
                8) set_language_chinese ;;
                9) echo -e "${CYAN}平台: $OS_TYPE | 桌面: 未安装${RESET}" ;;
                0) echo -e "${GREEN}感谢使用 Chick 脚本！再见 🐤${RESET}"; exit 0 ;;
                *) echo -e "${RED}>>> 无效数字。${RESET}" ;;
            esac
        fi

        echo ""
        printf "  ${CYAN}按回车键返回主菜单...${RESET}"
        safe_read _ || continue
    done
}

# ============================================================
#  启动流程
# ============================================================
check_dependencies
install_self || true
main_menu