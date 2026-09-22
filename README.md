# 在 GB10（DGX Spark, ARM64）上玩 Steam 游戏的完整方法

> 实测环境：NVIDIA DGX Spark（GB10，ARM64）+ Ubuntu 24.04.4 LTS + 显卡驱动 580.173.02
> 已验证游戏：坎巴拉太空计划（Kerbal Space Program）、CS2（Counter-Strike 2）
> 本文所有命令均在该机器上实测跑通，实测日期 2026-09-22。

## 一、原理一句话

GB10 是 ARM 架构的电脑，Windows/Intel 的游戏（x86）不能直接跑。官方方案用三层翻译：

```
Windows 游戏（x86 指令）
    ↓  FEX 模拟器        —— x86 指令翻译成 ARM64（游戏逻辑部分）
    ↓  Proton + DXVK     —— Windows 图形接口翻译成 Vulkan
    ↓  显卡原生驱动       —— GB10 显卡直接渲染，这部分是 ARM 原生，几乎无损耗
```

关键点：图形渲染走显卡原生驱动，不经过模拟器翻译，所以 3A 游戏帧率接近原生。只有游戏逻辑（CPU 端）有模拟损耗。

## 二、安装（一条命令，官方方案）

```bash
sudo snap install steam --stable
```

这是 Canonical 官方发布的 ARM64 稳定版 Steam，内置了上面说的全套翻译组件，**不需要手动装模拟器、不需要折腾**。

首次启动会下载约 1 个 GB 的运行环境，耐心等几分钟。

更新（含新模拟器）：

```bash
sudo snap refresh steam
```

## 三、实测游戏清单（2026-09-22 核实）

| 游戏 | 应用编号 | 体量 | 体验 | 备注 |
|------|:--:|:--:|------|------|
| 坎巴拉太空计划 | 220200 | ~7 吉瓦 | 流畅 | Unity 引擎，模拟器下兼容性最好 |
| CS2 | 730 | 71 吉瓦 | 流畅 | 实测已装，9 月 22 日还在玩 |
| 赛博朋克 2077 | 2077 | — | 45~55 帧（1080p 光追）；开 DLSS4 可达 175+ 帧 | 参考数据 |
| 毁灭战士 永恒 | — | — | 流畅 | 参考数据 |

游戏数据目录（实测）：

```
~/snap/steam/common/.local/share/Steam/steamapps/common/
├── Kerbal Space Program/
└── Counter-Strike Global Offensive/   ← CS2 的安装目录名
```

### 坎巴拉中文汉化

Steam 界面不稳定时无法切语言，直接改游戏内配置：

1. 从 GitHub `jhihyulin/KSP-Language` 下载 `dictionary.cfg`
2. 替换 `GameData/Squad/Localization/dictionary.cfg`
3. 在游戏 `settings.cfg` 里设 `LANGUAGE = zh-tw`
4. 重启游戏

## 四、远程玩（串流到台式机）

GB10 可以当"游戏主机"，台式机装客户端远程串流画面，键鼠/手柄延迟低：

```
GB10 显卡 → 画面采集 → Sunshine 串流服务 → 网络 → Moonlight 客户端（台式机）
```

### 1. GB10 端装串流服务

```bash
# 从 GitHub 发布页找 ubuntu-24.04-arm64 安装包
sudo dpkg -i sunshine_*.deb
sudo systemctl enable --now sunshine
# 设置串流账号密码
sunshine --creds 用户名 密码
```

实测版本：Sunshine 2026.516.143833，编码用显卡硬件编码器（NVENC），抓屏走 X11。

### 2. 台式机端装客户端

从 Moonlight 官网或 GitHub 发布页下载 Windows 版，安装后：

- 局域网内自动发现 GB10（或手动填 GB10 的局域网 IP）
- 输入上面设置的账号密码
- 首次连接需在串流网页端（`http://GB10的IP:47990`）提交配对码
- 连接后选"桌面"或具体游戏即可

实测端口：47984（画面）、47989（控制）、47990（网页配置端）。

## 五、坑与对策（全部实测踩过）

1. **Steam 界面偶尔崩溃** —— 模拟环境下 Steam 的网页界面组件（V8 引擎）翻译不完整，闪退属正常现象。退出重进即可，**下载进度会续传**；游戏启动后运行不受 Steam 崩溃影响。
2. **命令行下载游戏（绕过闪退的界面）**：

   ```bash
   # 下载命令行工具
   curl -sqL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar zxvf -
   # 关键：必须用 snap 内置的模拟器壳启动，系统级的会报"根文件系统不存在"
   /snap/steam/current/usr/bin/FEXBash ./steamcmd.sh +login 账号 +app_update 应用编号 +quit
   ```

3. **GB10 没有独立外网**（国际带宽限制）—— 国外下载源慢或不通。下载游戏/文件先在台式机上下载好，再 `scp` 拷到 GB10。国内镜像源（清华/百度）可用。
4. **snap 更新节奏慢** —— `snap refresh` 显示"无更新"是正常的，官方发布节奏滞后于模拟器独立版本。
5. **游戏选型** —— 优先选 Unity 引擎、无强反作弊的单机游戏；带 EAC/BattlEye 反作弊的网游会封杀模拟环境，别尝试。

## 六、验证记录（可复现）

```bash
# Steam 已装
snap list | grep steam
# 预期: steam 1.0.0.85  245  latest/beta  canonical**

# 串流服务在跑、端口监听中
systemctl is-active sunshine        # active
ss -tlnp | grep -E '47984|47989|47990'

# 游戏清单（看应用名称和安装目录）
grep -H '"name"' ~/snap/steam/common/.local/share/Steam/steamapps/*.acf
```
