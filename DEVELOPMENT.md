# Development

## 工具链与目标环境

- 构建输出（上架或模拟上架）：**支持 iOS >= 15.0，最低部署版本为 iOS 15.0**。
- 模拟器验证目标：**iPhone 12 + iOS 17**；本机已安装 runtime 对应系统版本为 iOS 17.0.1。
- 当前主机：**macOS 27.2，Apple Silicon arm64**。
- 命令行工具链：**Xcode 27.2（27B52）**，位于 `/Applications/Xcode.app`。
- 构建入口：`PresetApp.xcworkspace`，scheme 为 `PresetApp`。
- 2026-11-14 检查时 `/Applications/Xcode15.app`、`/Applications/Xcode12.app` 均已不存在。

不要求 Xcode IDE 能打开；构建和模拟器操作使用命令行，每条命令显式设置
`DEVELOPER_DIR`，不依赖或修改全局 `xcode-select`。

构建 SDK、最低部署版本和模拟器运行系统分别管理。iOS 17 模拟器验证不代表已完成
iOS 15 的实际运行兼容性验证；高于 iOS 15.0 的 API 需要可用性检查及兼容路径。

**配置现状**：工程 Project / Target 的 Debug / Release 四处
`IPHONEOS_DEPLOYMENT_TARGET` 和 `PresetDeviceInfo/Package.swift` 当前仍为 `15.5`。
后续需统一为 `15.0`，再验收最低版本。2026-11-14 已沿用现有 15.5 配置通过
Xcode 27.2 的 Debug / Release 模拟器完整构建，并完成 iPhone 12 / iOS 17.0.1 安装、
启动、Home / Bill / Profile 和 HTTP POST 验证；同一模拟器再次冷启动并启动 Debug App 也通过。
Release 目前仅完成构建，未安装运行。Debug 已通过 mock 登录、杀进程后的会话恢复及登出数据清除；
2026-11-14 用户确认简单验收通过，结束本轮验证并关闭模拟器。未执行的交互项见环境文档的本轮验证记录。

## 构建输出验收

“模拟上架”指 Release / Archive 流程验证，不包含上传或 App Store 审核。
先将工程和本地 package 的最低部署版本统一为 iOS 15.0，再检查有效配置并归档：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp -showBuildSettings

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/PresetApp-release-check.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive
```

归档成功后检查 `.xcarchive/Products/Applications/PresetApp.app/Info.plist` 的
`MinimumOSVersion` 为 `15.0`。无签名归档用于流程检查，正式发行还需验证签名与导出；
免费 Personal Team 仅用于个人开发测试，不能用于 App Store 或 TestFlight 分发。

## iPhone 12 / iOS 17 模拟器验证

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list runtimes
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
```

优先复用已有匹配设备；没有时再创建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl create 'iPhone 12 - iOS 17' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-12 \
  com.apple.CoreSimulator.SimRuntime.iOS-17-0
```

本机 runtime 显示名称为 iOS 17.0，实际版本为 17.0.1；以上使用其 runtime 标识。
已有 iPhone 12 设备 UDID 为 `EB5976BB-75ED-4038-9B5E-686708B05E4A`，优先复用。
需要查看和操作界面时，打开 `/Applications/Xcode.app/Contents/Applications/DeviceHub.app`；
本机新版 Xcode 使用 Device Hub，旧 Simulator.app 路径已不存在。
记录查询或创建得到的 UDID，并在同一个 zsh 会话中执行：

```bash
PRESET_SIM_UDID='<目标模拟器 UDID>'
PRESET_SIM_BUILD_DIR="$(mktemp -d /tmp/preset-sim-build.XXXXXX)"

# 设备未启动时执行 boot；已启动时直接检查 bootstatus
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl boot "$PRESET_SIM_UDID"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl bootstatus "$PRESET_SIM_UDID" -b

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
  -configuration Debug -destination "platform=iOS Simulator,id=$PRESET_SIM_UDID" \
  -derivedDataPath "$PRESET_SIM_BUILD_DIR" CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl install "$PRESET_SIM_UDID" \
  "$PRESET_SIM_BUILD_DIR/Build/Products/Debug-iphonesimulator/PresetApp.app"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl launch "$PRESET_SIM_UDID" com.lisitede.preset.app
```

仅在前一步成功后继续下一步。分别记录 runtime 可用性、设备启动、App 完整构建、
安装和启动结果，随后验证页面导航、Profile 登录、杀进程后的会话恢复与登出。
不能仅凭 runtime 被识别或 Swift 编译通过就认定整体验收通过。

环境与历史阻塞见 [.context/init-ios-mac.md](.context/init-ios-mac.md)，
Profile 流程验收标准见 [.context/current-task.md](.context/current-task.md)。
真机免费 Personal Team 的账户配置、命令行签名、安装步骤也在环境文档中维护。

## 历史验证记录

以下结果保留排障价值，不再作为当前操作步骤：

- 旧基线为 iOS 14.0，验证设备为 iPhone 12 / iOS 14.5，使用 Xcode 12.5.1 / Swift 5.4。
  曾观察到 Xcode 15.0.1 / Swift 5.9 产物在 iOS 14.5 启动期 SIGBUS，不能仅凭
  `MinimumOSVersion` 判断旧系统的实际运行结果。
- 2026-11-13 在 macOS 27.2 上验证 iOS 15.5 runtime：CoreSimulator 明确报告主机不支持，
  创建设备失败；Xcode 15.4 的 workspace 构建另有资源编译阻塞。细节已合并至环境文档的
  “历史验证：iPhone 12 / iOS 15.5”小节。
- 2026-08-02 曾在另一台 macOS Sequoia 15.7.5（24G624）+ Xcode 26.2（17C52）机器上
  完成 iPhone 16e（iPhone17,5）/ iOS 26.5.2 的构建、Personal Team 签名和安装。
  当时 Xcode 15.4 的 Developer Disk Image 缺少该机型所需硬件 variant
  （`boardID: 4`、`chipID: 33088`），报
  `kAMDMobileImageMounterPersonalizedBundleMissingVariantError`；
  这是设备准备问题，不是调整 Deployment Target 或重新签名能够解决的问题。
- 旧“保留 macOS Sonoma、使用另一台 Sequoia 机器安装”的计划已被本机升级替代。
  当前使用 Xcode 27.2，真机设备连接、准备和签名仍需另行验收；
  免费 Personal Team 的 provisioning 通常约 7 天过期，需要重新签名安装。

工具链与主机的官方兼容范围见 [Xcode 支持矩阵](https://developer.apple.com/support/xcode/)。
