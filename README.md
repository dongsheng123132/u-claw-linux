# U-Claw Linux Bootable USB

> **把任意电脑变成 AI 工作站 — 插上 U 盘，开机即用**
>
> **Turn any computer into an AI workstation — just boot from USB**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[中文](#中文) | [English](#english)

---

<a id="中文"></a>

## 中文

### 这是什么

这是一个**完全独立**的项目，用于制作**可启动的 Linux AI U 盘**：

- 插上任意电脑，从 U 盘启动，直接进入 Ubuntu 桌面
- 一键安装 OpenClaw AI 助手，桌面图标双击即用
- 内置持久化存储，安装的软件和数据重启后保留
- **不需要目标电脑有任何操作系统**

> 与 [u-claw](https://github.com/dongsheng123132/u-claw) 便携版的区别：便携版需要电脑已有 Windows/Mac 系统，本项目连系统都不需要。

### 技术方案概览

```
┌────────────────────────────────────────────┐
│                U 盘结构                      │
│                                            │
│  Ventoy 引导区（隐藏分区）                   │
│    - BIOS + UEFI 双模式启动                  │
│    - 开源引导管理器 v1.0.99                  │
│                                            │
│  Ventoy 数据分区（可见）                     │
│    ubuntu-24.04.2-desktop-amd64.iso  5.8GB │
│    persistence.dat                   20GB  │
│    ventoy/ventoy.json                配置   │
│    u-claw-linux/                     脚本   │
│      ├── setup-openclaw.sh                 │
│      └── start-openclaw.sh                 │
└────────────────────────────────────────────┘
```

**三个核心技术选型：**

| 技术 | 为什么选它 |
|------|-----------|
| **Ventoy 1.0.99** | ISO 文件直接丢进去就能启动，不用烧录，可放多个系统 |
| **Ubuntu 24.04 LTS** | 长期支持版，驱动兼容性最好，社区最大 |
| **casper-rw 持久化** | 让 Live USB 也能保存数据，重启不丢失 |

### 硬件要求

| 项目 | 要求 |
|------|------|
| U 盘 | **32GB+**，强烈推荐 USB 3.0（蓝色接口） |
| 制作环境 | Windows 10/11，PowerShell 5.1+ |
| 目标电脑 | x86_64（Intel / AMD），任意品牌 |
| 网络 | 首次安装 OpenClaw 时需要联网 |

### 快速制作（4 步）

在 Windows 上以**管理员身份**打开 PowerShell：

```powershell
cd path\to\u-claw-linux

# Step 1: 下载 Ventoy 并写入 U 盘（会格式化 U 盘！）
.\1-prepare-usb.ps1

# Step 2: 下载 Ubuntu 24.04 ISO（~5.8GB，国内镜像）
.\2-download-iso.ps1

# Step 3: 创建持久化镜像（默认 20GB）
.\3-create-persistence.ps1

# Step 4: 拷贝所有文件到 U 盘
.\4-copy-to-usb.ps1
```

### 每一步做了什么

#### Step 1: 写入 Ventoy 引导 (`1-prepare-usb.ps1`)

- 列出所有 USB 设备，让你选择
- 从 GitHub 下载 Ventoy 1.0.99
- 启动 Ventoy2Disk.exe GUI 界面
- 你在 GUI 中选择 U 盘 → 点 Install
- **注意：会格式化 U 盘，数据全丢！**

#### Step 2: 下载 Ubuntu ISO (`2-download-iso.ps1`)

- 从国内镜像下载 Ubuntu 24.04.2 桌面版
- 镜像优先级：清华 → 阿里 → 中科大 → 官方
- 自动 SHA256 校验确保文件完整
- 有缓存机制，不会重复下载

#### Step 3: 创建持久化镜像 (`3-create-persistence.ps1`)

这是整个方案最关键的一步。

- 检测是否安装了 WSL（Windows 子系统 Linux）
- **有 WSL**：直接用 `mkfs.ext4` 创建格式化好的 ext4 镜像
- **没 WSL**：创建稀疏文件，首次进 Linux 后需要手动格式化
- 卷标必须是 `casper-rw`（Ubuntu 持久化的约定）
- 默认 20GB，可选 1-28GB

#### Step 4: 拷贝到 U 盘 (`4-copy-to-usb.ps1`)

- 自动识别 Ventoy U 盘（通过卷标）
- 检查剩余空间
- 拷贝 4 样东西：ISO、persistence.dat、ventoy.json、安装脚本

### 使用方法

#### 首次使用

1. 将 U 盘插入目标电脑
2. 开机按启动键进入 BIOS 启动菜单：

| 品牌 | 启动键 |
|------|--------|
| Dell 戴尔 | F12 |
| Lenovo 联想 | F12 |
| HP 惠普 | F9 |
| ASUS 华硕 | F2 或 DEL |
| Acer 宏碁 | F12 |
| MSI 微星 | F11 |
| Huawei 华为 | F12 |
| Xiaomi 小米 | F12 |

3. 在启动菜单选择 USB 设备
4. Ventoy 菜单出现 → 选择 Ubuntu
5. 等待 Ubuntu 桌面加载
6. 连接 Wi-Fi
7. 打开终端（右键桌面 → Open Terminal，或 `Ctrl+Alt+T`）
8. 运行安装命令：

```bash
sudo bash /media/*/Ventoy/u-claw-linux/setup-openclaw.sh
```

9. 安装完成，桌面出现 **"U-Claw AI Assistant"** 图标
10. 双击图标 → 浏览器打开 → 配置 AI 模型

#### 日常使用

以后每次只需要：

1. 插入 U 盘 → 开机选 USB → 进入 Ubuntu
2. 双击桌面 **"U-Claw AI Assistant"** 图标
3. 所有数据自动保留，无需重新安装

### 安装脚本详解 (`setup-openclaw.sh`)

脚本完成 9 个步骤：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 检查 root 权限 | 必须 `sudo` 运行 |
| 2 | 安装系统依赖 | `curl`, `xdg-utils` |
| 3 | 创建目录 | `/opt/u-claw/{runtime,core,data}` |
| 4 | 下载 Node.js v22 | 国内镜像优先，官方回退 |
| 5 | 创建 package.json | 最小化包描述 |
| 6 | 安装 OpenClaw | `npm install openclaw` + QQ 插件 |
| 7 | 写默认配置 | gateway + token |
| 8 | 安装启动脚本 | 复制到 `/opt/u-claw/` |
| 9 | 创建桌面快捷方式 | 可选开机自启 |

**完全自包含**：脚本内硬编码了所有 URL 和路径，不依赖本仓库中的任何其他文件。

### 文件结构

```
u-claw-linux/
├── README.md                      本文件
├── LICENSE                        MIT 协议
├── .gitignore
│
├── 1-prepare-usb.ps1              Step 1: 下载 Ventoy + 写入 U 盘
├── 2-download-iso.ps1             Step 2: 下载 Ubuntu ISO
├── 3-create-persistence.ps1       Step 3: 创建持久化镜像
├── 4-copy-to-usb.ps1              Step 4: 拷贝到 U 盘
│
├── linux-setup/                   进入 Linux 后使用的脚本
│   ├── setup-openclaw.sh          一键安装 OpenClaw
│   ├── start-openclaw.sh          启动脚本
│   └── openclaw.desktop           桌面快捷方式定义
│
└── ventoy/
    └── ventoy.json                Ventoy 持久化配置
```

### 核心配置文件

#### `ventoy/ventoy.json`

```json
{
  "persistence": [
    {
      "image": "/ubuntu-24.04.2-desktop-amd64.iso",
      "backend": "/persistence.dat",
      "autosel": 1
    }
  ]
}
```

告诉 Ventoy：启动 Ubuntu ISO 时，自动加载 `persistence.dat` 作为持久化后端。`autosel: 1` 表示自动选择，不弹确认框。

#### Linux 端环境变量

| 变量 | 值 |
|------|-----|
| `OPENCLAW_HOME` | `/opt/u-claw/data/.openclaw` |
| `OPENCLAW_STATE_DIR` | `/opt/u-claw/data/.openclaw` |
| `OPENCLAW_CONFIG_PATH` | `/opt/u-claw/data/.openclaw/openclaw.json` |

#### OpenClaw 配置格式

```json
{
  "gateway": {
    "mode": "local",
    "auth": { "token": "uclaw" }
  },
  "agent": {
    "model": "deepseek-chat",
    "apiKey": "sk-xxx",
    "baseURL": "https://api.deepseek.com/v1"
  }
}
```

### 实践经验与注意事项

#### 制作阶段

1. **U 盘选择很重要**
   - 必须 32GB+（ISO 5.8GB + 持久化 20GB + 系统开销）
   - 强烈建议 USB 3.0，否则启动和运行都会很慢
   - 推荐品牌：闪迪、金士顿、三星（杂牌盘容易出问题）
   - 避免使用 USB Hub，直接插主板接口

2. **Step 1 格式化会清空 U 盘**
   - Ventoy 安装会格式化整个 U 盘
   - **务必提前备份 U 盘上的数据**
   - 脚本会列出所有 USB 设备让你确认，看清楚再操作

3. **Step 3 持久化镜像**
   - 如果你的 Windows 上有 WSL，脚本会自动用它创建 ext4 格式的镜像（最省事）
   - 如果没有 WSL，会创建空文件，首次进 Linux 后需要手动格式化：
     ```bash
     sudo mkfs.ext4 -F -L casper-rw /media/*/Ventoy/persistence.dat
     ```
     格式化后**重启**才能生效
   - 大小建议：32GB U 盘选 20GB，64GB U 盘可以选 40GB+

4. **ISO 下载**
   - 脚本默认走清华/阿里/中科大国内镜像，无需翻墙
   - 如果全部失败，可以手动下载 Ubuntu ISO 放到 `.download-cache/` 目录

#### 启动阶段

5. **Secure Boot 问题**
   - 部分电脑需要关闭 Secure Boot 才能从 U 盘启动
   - 进入 BIOS → Security → Secure Boot → Disabled
   - 不同品牌进 BIOS 的方式不同（通常是 DEL 或 F2）

6. **找不到 USB 启动项**
   - 确认 U 盘插好了（换个 USB 口试试）
   - 有些电脑默认禁用了 USB 启动，需要在 BIOS 中开启
   - Legacy/CSM 模式和 UEFI 模式都试试

7. **Ubuntu 桌面加载慢**
   - 正常现象，Live USB 从 U 盘读取，比硬盘慢
   - USB 3.0 U 盘 + USB 3.0 接口会快很多
   - 首次加载约 1-3 分钟

#### 使用阶段

8. **Wi-Fi 连接**
   - Ubuntu 24.04 支持大多数 Wi-Fi 芯片
   - 如果 Wi-Fi 不行，可以用手机 USB 共享网络
   - 或使用 USB 无线网卡

9. **OpenClaw 安装需要网络**
   - `setup-openclaw.sh` 需要联网下载 Node.js 和 npm 包
   - 国内镜像优先，无需翻墙
   - 安装过程约 1-2 分钟（取决于网速）

10. **端口冲突**
    - OpenClaw 网关使用端口 18789-18799
    - 如果启动失败提示端口占用，说明上次没正常关闭
    - 关闭终端窗口再重新打开即可

11. **数据在哪里**
    - 所有数据保存在持久化镜像中（`persistence.dat`）
    - 安装目录：`/opt/u-claw/`
    - 配置文件：`/opt/u-claw/data/.openclaw/openclaw.json`
    - 重启后数据保留，除非你重新格式化 U 盘

12. **性能预期**
    - U 盘运行肯定比硬盘慢，这是物理限制
    - AI 推理在云端，本地只跑网关，所以 AI 对话速度不受影响
    - 如果觉得系统太卡，建议用 USB 3.0 U 盘

#### 常见故障排查

| 问题 | 解决方案 |
|------|---------|
| 无法从 U 盘启动 | BIOS 关闭 Secure Boot，开启 USB Boot |
| Ventoy 菜单无 Ubuntu 选项 | 检查 ISO 是否正确放在 Ventoy 数据分区根目录 |
| 持久化不生效（重启数据丢失） | 检查 persistence.dat 是否已格式化为 ext4，卷标是否为 `casper-rw` |
| OpenClaw 安装失败 | 检查网络连接，确认能访问 npmmirror.com |
| 浏览器打不开 | 手动打开浏览器，访问 `http://localhost:18789` |
| 屏幕分辨率不对 | Settings → Displays → Resolution |

### 支持的 AI 模型

| 模型 | 推荐场景 | 备注 |
|------|---------|------|
| DeepSeek | 编程首选 | 极便宜 |
| Kimi K2.5 | 长文档 | 256K 上下文 |
| 通义千问 Qwen | 通用 | 免费额度大 |
| 智谱 GLM | 学术 | — |
| MiniMax | 多模态 | — |
| 豆包 Doubao | 火山引擎 | — |

国际模型（Claude / GPT / Gemini）需翻墙或中转。

### 与主项目的关系

本仓库是 [U-Claw](https://github.com/dongsheng123132/u-claw) 项目的 **Linux 可启动版**，完全独立维护：

| 仓库 | 定位 | 目标平台 |
|------|------|---------|
| [u-claw](https://github.com/dongsheng123132/u-claw) | 便携 U 盘 + 桌面安装版 | Mac / Windows |
| **u-claw-linux**（本仓库） | 可启动 Linux U 盘 | 任意 x86_64 电脑 |

### 联系

- WeChat / 微信: hecare888
- GitHub: [@dongsheng123132](https://github.com/dongsheng123132)
- Website / 官网: [u-claw.org](https://u-claw.org)

---

<a id="english"></a>

## English

### What is this

A **fully independent** project for creating a **bootable Linux AI USB drive**:

- Boot any computer from USB, straight into Ubuntu desktop
- One-click install OpenClaw AI assistant with desktop shortcut
- Built-in persistence — installed software and data survive reboots
- **No operating system needed on the target computer**

> Differs from [u-claw](https://github.com/dongsheng123132/u-claw) portable: portable version needs Windows/Mac already installed. This project needs nothing.

### Requirements

| Item | Requirement |
|------|-------------|
| USB Drive | **32GB+**, USB 3.0 recommended |
| Build machine | Windows 10/11, PowerShell 5.1+ |
| Target PC | x86_64 (Intel/AMD), any brand |
| Network | Required for first-time OpenClaw install |

### Quick Start (4 Steps)

Open PowerShell **as Administrator** on Windows:

```powershell
cd path\to\u-claw-linux

.\1-prepare-usb.ps1       # Download Ventoy + write to USB (FORMATS the drive!)
.\2-download-iso.ps1      # Download Ubuntu 24.04 ISO (~5.8GB, China mirrors)
.\3-create-persistence.ps1 # Create persistence image (default 20GB)
.\4-copy-to-usb.ps1       # Copy everything to USB
```

### How to Boot

1. Insert USB into target computer
2. Press boot key during startup:

| Brand | Boot Key |
|-------|----------|
| Dell | F12 |
| Lenovo | F12 |
| HP | F9 |
| ASUS | F2 or DEL |
| Acer | F12 |
| MSI | F11 |

3. Select USB device → Ventoy menu → Ubuntu
4. Once on Ubuntu desktop, connect to Wi-Fi
5. Open Terminal and run:

```bash
sudo bash /media/*/Ventoy/u-claw-linux/setup-openclaw.sh
```

6. Double-click **"U-Claw AI Assistant"** on desktop
7. Configure your AI model in the browser

### Daily Use

1. Insert USB → Boot from BIOS → Ubuntu desktop
2. Double-click desktop icon
3. All data persists automatically

### Technical Details

- **Ventoy 1.0.99**: Open-source boot manager, supports ISO/WIM/VHD, BIOS + UEFI
- **Persistence**: Ventoy persistence plugin with `casper-rw` labeled ext4 image
- **Node.js**: v22.14.0 LTS, downloaded from npmmirror.com (China) or nodejs.org
- **OpenClaw**: Latest version from npm, installed to `/opt/u-claw/`
- **Completely independent**: Does not reference any files from the main u-claw repo

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't boot from USB | Disable Secure Boot in BIOS, enable USB Boot |
| No Ubuntu in Ventoy | Check ISO is in Ventoy data partition root |
| Persistence not working | Ensure persistence.dat is ext4 with label `casper-rw` |
| OpenClaw install fails | Check network, ensure npmmirror.com is reachable |
| Browser won't open | Manually open browser to `http://localhost:18789` |

### Related

| Repo | Purpose | Platform |
|------|---------|----------|
| [u-claw](https://github.com/dongsheng123132/u-claw) | Portable USB + Desktop app | Mac / Windows |
| **u-claw-linux** (this repo) | Bootable Linux USB | Any x86_64 PC |

### Contact

- WeChat: hecare888
- GitHub: [@dongsheng123132](https://github.com/dongsheng123132)
- Website: [u-claw.org](https://u-claw.org)

---

**Made with care by [dongsheng](https://github.com/dongsheng123132)**
