# Development

## 工具链与目标环境

- 项目 Deployment Target：**iOS 14.0**
- 最低兼容验证目标：**iPhone 12 + iOS 14.5**（Xcode 12.5.1 官方 bundle 实际提供的 iOS 14 系列运行时为 14.5）
- 默认开发工具链：**Xcode 15.4（15F31d）**，位于 `/Applications/Xcode.app`
- iOS 14.5 兼容性工具链：**Xcode 12.5.1（12E507）**，位于 `/Applications/Xcode12.app`
- iPhone 16e 真机安装工具链：另一台 **macOS Sequoia 15.7.5（24G624）** 机器上的 **Xcode 26.2（17C52）**（2026-08-02 已验证，支持 iPhone 16e 的下限为 Xcode 16.3）

> iOS 13 所需的 Xcode 11 在当前 Apple Silicon 环境不可用，故最低兼容目标定为 iOS 14。

日常开发默认使用 Xcode 15.4，不全局切换到 Xcode 12.5.1。当前选择应满足：

```bash
xcode-select -p
# /Applications/Xcode.app/Contents/Developer

xcodebuild -version
# Xcode 15.4
# Build version 15F31d
```

仅在执行 iOS 14.5 兼容性构建时，通过命令级 `DEVELOPER_DIR` 显式调用 Xcode 12.5.1。

## Xcode 15.4 日常开发

使用 Xcode 15.4 打开工作区，不要直接打开 `.xcodeproj`：

```bash
open -a Xcode PresetApp.xcworkspace
```

在 Xcode 中使用 `PresetApp` scheme，并始终保持 `IPHONEOS_DEPLOYMENT_TARGET = 14.0`。Xcode 15.4 的 GUI 构建和默认 `xcodebuild` 用于日常开发；其构建结果不作为 iOS 14.5 兼容性验收结果。

## 获取 iOS 14.5 运行时

**前提**：已放置 `/Applications/Xcode12.app`（Xcode 12.5.1，无需通过 GUI 启动；其 bundle 用于提供 iOS 14.5 运行时和兼容性构建器）。

运行时位置：
```
/Applications/Xcode12.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime
```

```bash
mkdir -p ~/Library/Developer/CoreSimulator/Profiles/Runtimes

ln -sf "/Applications/Xcode12.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime" \
  "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 14.5.simruntime"

xcrun simctl shutdown all
killall -9 com.apple.CoreSimulator.CoreSimulatorService

# 验证：应列出 iOS 14.5 - com.apple.CoreSimulator.SimRuntime.iOS-14-5
xcrun simctl list runtimes
```

> 注：`xcrun simctl runtime add` 仅接受 `.dmg` 格式，不接受 `.simruntime` 目录；故采用软链到用户级 `Profiles/Runtimes/` 的方式注册。

## 创建验证设备

```bash
xcrun simctl create "iPhone 12" "com.apple.CoreSimulator.SimDeviceType.iPhone-12" "com.apple.CoreSimulator.SimRuntime.iOS-14-5"
# 记录返回的 UDID
```

## iOS 14.5 兼容性构建与运行

本节的兼容性验证必须使用 Xcode 12.5.1 编译。项目曾验证 Xcode 15.0.1（Swift 5.9）产物运行在 iOS 14.5（Swift 5.4 runtime）时会在启动期 SIGBUS 崩溃；Xcode 15.4 使用 Swift 5.10，其产物不能替代 Xcode 12.5.1 的 iOS 14.5 兼容性验证。

```bash
UDID=<上一步返回的UDID>
xcrun simctl boot "$UDID"
open -a Simulator

# 编译（必须用 Xcode 12.5.1）
DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer \
xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
  -destination "platform=iOS Simulator,id=$UDID" \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PresetApp-*/Build/Products/Debug-iphonesimulator/PresetApp.app -maxdepth 0 | head -1)
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" com.lisitede.preset.app
```

> 注：日常开发仍使用 Xcode 15.4。每次在 Xcode 15.4 与 Xcode 12.5.1 之间切换构建器后，都应清理 DerivedData（`xcodebuild clean`），避免残留产物干扰。

## iPhone 16e + iOS 26 真机安装

验证设备：**iPhone 16e（iPhone17,5）+ iOS 26.5.2**。

Xcode 15.4 可以识别该设备，但其 Developer Disk Image 不包含 iPhone 16e 所需的硬件 variant（`boardID: 4`、`chipID: 33088`），因此 Device Preparation、Xcode GUI 安装和 `devicectl device install app` 均会失败：

```text
kAMDMobileImageMounterPersonalizedBundleMissingVariantError
The bundle image is missing the requested variant for this device.
```

这不是 App、开发证书、Provisioning Profile 或 Deployment Target 的问题，重启、重新配对或重新签名无法解决。

- 支持 iPhone 16e 的可靠下限为 **Xcode 16.3**。
- Xcode 16.3 要求 **macOS Sequoia 15.2 或更高版本**；macOS Sonoma 14.8.4 无法正常运行。
- 任何非 Xcode 12.5.1 构建的产物（无论 Xcode 15.4 还是 Sequoia 机器上的 Xcode 16.3+，即使保留 `MinimumOSVersion = 14.0`）均不能替代 iOS 14.5 兼容性验证。
- 免费 Personal Team 生成的 Provisioning Profile 有效期为 7 天，到期后需要重新签名并安装。

推荐将构建环境与真机安装环境分开：当前机器以 Xcode 15.4 作为默认开发工具，以 Xcode 12.5.1 执行 iOS 14.5 兼容性验证；另一台 macOS Sequoia + Xcode 16.3（或更高版本）机器负责 iPhone 16e 真机安装。

Xcode 与 macOS 的官方兼容范围见 [Xcode 支持矩阵](https://developer.apple.com/support/xcode/)。

### 已验证的 iPhone 16e 安装流程（2026-08-02）

真机安装机器实际环境：**macOS Sequoia 15.7.5（24G624）+ Xcode 26.2（17C52）**，`xcode-select` 指向 `/Applications/Xcode.app`。工程完整存在于该机器，直接在该机器构建并签名，可避免跨机传输的 `.app` 其 Provisioning Profile 不含设备 UDID 的问题。

```bash
# 确认设备已连接（State 为 connected），并记录其 Identifier 作为 UDID
xcrun devicectl list devices

open -a Xcode PresetApp.xcworkspace
```

1. `PresetApp` target → Signing & Capabilities：勾选 **Automatically manage signing**，Team 选择 Personal Team；保持 `IPHONEOS_DEPLOYMENT_TARGET = 14.0`。
2. 设备选择器选中 iPhone 16e，等待 Device Preparation 完成。
3. `Product → Build`（仅构建，无需调试运行）。
4. 命令行安装：

```bash
UDID=<devicectl 输出的设备 Identifier>
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PresetApp-*/Build/Products/Debug-iphoneos/PresetApp.app -maxdepth 0 | head -1)
xcrun devicectl device install app --device "$UDID" "$APP_PATH"
```

安装后在手机上直接点开运行。Profile 7 天到期后重复第 3、4 步重新安装即可。

## macOS Sequoia 升级评估（非当前计划）

当前机器为 **MacBook Air (M1, MacBookAir10,1, 16 GB)**，硬件支持 macOS Sequoia。2026-08-02 通过 `softwareupdate --list-full-installers` 检查时，Apple 向该设备提供的最新 Sequoia 完整安装器为 **macOS Sequoia 15.7.8**。

```bash
softwareupdate --fetch-full-installer --full-installer-version 15.7.8
```

上述命令只下载安装器，实际升级仍需人工打开 `/Applications/Install macOS Sequoia.app` 并确认。检查时系统盘约剩余 45 GB；升级前建议至少释放到 60 GB，若还要并存多套 Xcode，建议预留 80 GB，并先完成完整备份。

> 当前计划是不升级本机 macOS，继续保留 macOS Sonoma 14.8.4 + Xcode 15.4。硬件支持升级不代表旧 Xcode 工具链仍受支持；Xcode 15.4 的官方系统范围止于 macOS Sonoma 14.x，优先使用另一台 Sequoia 机器承担真机安装。
