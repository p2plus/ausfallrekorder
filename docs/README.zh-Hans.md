# Ausfallrekorder

[English](../README.md) · [Deutsch](README.de.md) · 简体中文

一个小而实用的工具，只做好两件事：**测量网络连接**，以及**生成清晰的报告**。

<img src="../Resources/AppIcon.png" width="96" alt="应用图标">

<img src="images/menubar-zh-Hans.png" width="350" alt="简体中文菜单栏界面">

## macOS

应用位于菜单栏，不占用大窗口。点击波形图标，选择**开始记录**。
**导出**可以保存离线 HTML 报告或原始记录文件。**退出**会先停止并保存记录，
再关闭应用。关闭弹出面板不会停止记录。

需要 macOS 14 或更新版本。下载请前往 [Releases](https://github.com/p2plus/ausfallrekorder/releases)。
当前应用采用本地签名，尚未通过 Apple 公证。

从源码构建需要 Swift 6 或更新版本：

```sh
sh scripts/build-macos.sh
open dist/Ausfallrekorder.app
```

## Linux

Linux 版本为命令行工具，与 Mac 应用使用相同的测量核心和文件格式。
已在 Ubuntu 24.04 ARM64 上测试，另设有 x86_64 CI。

```sh
sudo apt install iproute2 iputils-ping libc-bin libcurl4t64 libstdc++6
./ausfallrekorder-cli record --language zh-Hans --label WLAN --output wifi.afr
```

按 **Ctrl+C** 停止，工具会保存记录并生成 HTML 报告。
默认每 15 秒检查一次，最多记录 8 小时。测量无需 root 权限，也不会安装后台服务。

```sh
./ausfallrekorder-cli report wifi.afr --language zh-Hans --output report.html
./ausfallrekorder-cli compare wifi.afr lan.afr --language zh-Hans --output comparison.html
```

## 轻量设计

每轮仅发送三个单独的 Ping、一次系统 DNS 查询和一次 HTTPS HEAD 请求。
不执行网速测试，不下载网页内容，不重叠执行检查。记录逐轮追加保存，
不会每次重写整个文件。应用不会阻止系统休眠，也没有持续动画。

支持英语、德语和简体中文。Mac 应用跟随系统首选语言，命令行可使用
`--language en`、`--language de` 或 `--language zh-Hans`。

## 结果的边界

两次检查之间的短暂中断可能无法被发现。休眠时间视为未观测时段。
Ping 失败不能证明运营商存在故障，DNS 也可能由系统缓存应答。
对比两台设备前，请确保时钟同步。

测试会连接 Cloudflare、Google 和 example.com，这些服务会看到正常的连接元数据。
测量记录不会上传。报告包含设备名称、时间、网络接口及路由器地址，分享前请检查。

[测试和资源测量](verification.md) · [完整技术说明](../README.md)
