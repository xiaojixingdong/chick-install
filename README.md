# 🐤 Chick — 云端桌面一键安装脚本

> 「从零开始，拥有一个属于你的云端桌面。」

一个开源、免费、无门槛的云端 Linux 桌面自动化脚本。写给每一个想折腾、想学习、想拥有自己云端空间的人。

![platform](https://img.shields.io/badge/platform-Linux%20%7C%20WSL%20%7C%20Codespaces%20%7C%20macOS%20%7C%20Termux-blue)
![license](https://img.shields.io/badge/license-MIT-green)

## 这是什么

一行命令，在你现有的 Linux / WSL / GitHub Codespaces 上装好一整套图形桌面环境——浏览器里就能用。不用买面板，不用手动敲几十条命令，不需要显示器。

## 功能

- 🖥️ **一键装桌面**：自选发行版与桌面环境，自动处理依赖
- ▶️ **桌面管理**：启动 / 停止 / 重新安装（更换桌面），带状态记录
- 🧩 **常用软件**：Chrome、Android Studio、Docker 等一键安装
- 🪟 **Windows 容器**（实验性，高风险）：Docker + KVM 运行 Windows
- 🛠️ **容器工具**：常用运维/容器工具集合
- 📊 **系统监控中心**：资源占用一览
- 🇨🇳 **中文环境**：一键把系统语言切成中文
- 🔁 **自安装**：装到 `~/.chick/`，之后直接敲 `chick` 打开

## 快速开始

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/xiaojixingdong/chick-install/main/chick.sh)
```

安装完成后：

```bash
chick            # 打开主菜单
chick --help     # 查看帮助
chick --version  # 查看版本
```

## 支持平台

| 平台 | 支持程度 |
|---|---|
| GitHub Codespaces / Linux 服务器 / WSL | ✅ 主力支持 |
| macOS / Termux | ⚠️ 实验性支持 |

## 菜单一览

```
1) ▶️  启动桌面
2) ⏹️  停止桌面
3) 🔄 重新安装 / 更换桌面
4) 🧩 安装软件
5) 🪟 安装 Windows 容器（高风险）
6) 📦 安装容器工具
7) 📊 系统监控中心
8) 🌐 设置系统语言为中文
9) ℹ️  状态信息
0) 🚪 退出
```

（未装桌面时菜单会自动精简为可用的那几项）

## 系统要求

- Bash 4+、curl 或 wget、sudo 权限
- 磁盘空间：桌面环境建议 ≥ 10 GB；Windows 容器建议 ≥ 64 GB
- Windows 容器需要 KVM 硬件加速（多数云主机默认关闭）

## 常见问题

**脚本会动我系统里已有的东西吗？**
自身状态只写在 `~/.chick/`；安装桌面/软件时走系统包管理器（apt 等），过程中有明确提示。

**支持非交互（CI）执行吗？**
菜单检测到非交互环境会自动退出，不会把 CI 卡住。

**怎么卸载？**
`rm -rf ~/.chick` 删掉脚本自身；桌面环境按对应发行版的方式卸载。

**Windows 容器装完特别卡？**
多半是没启用 KVM。用 `ls /dev/kvm` 检查；云主机需要在控制台开启嵌套虚拟化。

## 项目结构

```
chick-install/
└── chick.sh    # 全部逻辑，单文件
```

## 交流与反馈

遇到问题、想交流折腾心得？欢迎来 **Chick Zone** 社区：https://chickchat.cc.cd

## 联系

- 开发者：小鸡行动
- 邮箱：xiaojixingdong@gmail.com

## License

MIT
