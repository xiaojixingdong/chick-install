# 🐤 Chick 自动安装脚本 --1 / Chick Auto Install Script --1

> **开发者 / Developer:** 小鸡行动 (xiaojixingdong)
> **联系邮箱 / Email:** xiaojixingdong@gmail.com

一个在 GitHub Codespaces 中一键搭建 Linux 桌面环境的自动化脚本。  
One-click automated script to set up a Linux desktop environment in GitHub Codespaces.

---

## 📖 目录 / Table of Contents

- [这是什么 / What is this?](#-这是什么--what-is-this)
- [功能特性 / Features](#-功能特性--features)
- [快速开始 / Quick Start](#-快速开始--quick-start)
- [使用方法 / How to Use](#-使用方法--how-to-use)
- [支持的平台 / Supported Platforms](#-支持的平台--supported-platforms)
- [注意事项 / Important Notes](#-注意事项--important-notes)
- [常见问题 / FAQ](#-常见问题--faq)
- [联系方式 / Contact](#-联系方式--contact)

---

## 🐤 这是什么 / What is this?

这是一个在 **GitHub Codespaces** 终端中运行的自动化脚本，可以帮你快速搭建一个完整的 **Linux 桌面环境**（XFCE + noVNC），让你在浏览器里就能像用电脑一样使用 Linux 系统。

This is an automated script that runs in the **GitHub Codespaces** terminal. It helps you quickly set up a complete **Linux desktop environment** (XFCE + noVNC), allowing you to use a Linux system in your browser just like a real computer.

> 💡 **适合谁用？ / Who is this for?**
> - 没有电脑，想体验 Linux 桌面的用户
> - 想在云端学习编程的初学者
> - 想在小红书分享技术教程的博主

> 💡 **适合谁用？ / Who is this for?**
> - Users who don't have a computer but want to experience a Linux desktop
> - Beginners who want to learn programming in the cloud
> - Bloggers who want to share tech tutorials on social media

---

## ✨ 功能特性 / Features

| 功能 / Feature | 说明 / Description |
|---|---|
| 🖥️ Linux 桌面环境 | 一键安装 XFCE 轻量桌面 + noVNC 网页访问 |
| 📦 软件可选安装 | 支持 Chrome、Firefox、微信、QQ、Android Studio 等 |
| 🎨 精美菜单界面 | 使用 gum 打造现代终端 TUI 菜单 |
| 💾 状态记忆 | 自动检测已安装环境，下次打开直接启动 |
| 🌍 跨平台兼容 | 支持 Codespaces、Linux、macOS、WSL、Termux |
| ⚡ 全局命令 | 安装后只需输入 `chick` 即可召唤菜单 |

| Feature | Description |
|---|---|
| 🖥️ Linux Desktop | One-click XFCE desktop + noVNC web access |
| 📦 Optional Software | Chrome, Firefox, WeChat, QQ, Android Studio, etc. |
| 🎨 Beautiful Menu | Modern terminal TUI menu powered by gum |
| 💾 State Memory | Auto-detects installed environment, ready to launch next time |
| 🌍 Cross-platform | Supports Codespaces, Linux, macOS, WSL, Termux |
| ⚡ Global Command | Just type `chick` to open the menu after installation |

---

## 🚀 快速开始 / Quick Start

### 第一步 / Step 1：创建 Codespace

在 GitHub 上打开你的仓库，点击绿色的 **Code** 按钮 → **Codespaces** → **Create codespace on main**，等待网页版 VS Code 加载完成。

Open your repository on GitHub, click the green **Code** button → **Codespaces** → **Create codespace on main**, and wait for the web-based VS Code to load.

### 第二步 / Step 2：在终端运行一键命令

在 Codespaces 底部的**终端**中，复制粘贴以下命令并回车：

In the **terminal** at the bottom of Codespaces, copy and paste the following command and press Enter:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh)
