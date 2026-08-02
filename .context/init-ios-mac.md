# 在 macOS 上初始化 iPhone 开发环境

> updated_by: Codex
> updated_at: 2026-11-14 (Asia/Shanghai)
> platform: macOS on Apple Silicon (arm64)

---

## Shell 设置

**规范要求**：
- 必须使用 macOS 默认的 zsh（Apple Silicon 上系统自带，无需额外安装）

**检查步骤**：
1. 确认默认 shell：`echo $SHELL`，应为 `/bin/zsh`
2. 确认 zsh 版本：`zsh --version`，应为 5.9+
3. 确认运行架构：`arch`，应为 `arm64`
   > 注：`zsh --version` 输出中的 `x86_64-apple-darwin` 是 macOS 打包时写入的构建三元组，不代表实际运行架构；以 `arch` 为准。
4. 确认二进制类型：`file /bin/zsh`，应为 universal binary（含 arm64e）
5. 确认 `which zsh`，应返回 `/bin/zsh`

---

## Homebrew 设置

**规范要求**：
- 必须安装 Homebrew，用于管理命令行工具与依赖
- 架构为 Apple Silicon (arm64)，安装路径为 `/opt/homebrew`

**配置文件位置**：
- Homebrew PATH 初始化：`~/.zprofile`（Homebrew 官方推荐位置）

**检查步骤**：
1. 确认 Homebrew 安装：`brew --version`，应为 5.1.0+
2. 确认 Homebrew 路径：`which brew`，应返回 `/opt/homebrew/bin/brew`
3. 确认 PATH 初始化：`grep -E 'brew|/opt/homebrew' ~/.zprofile`，应含 `eval "$(/opt/homebrew/bin/brew shellenv)"`

**验证命令**：
- 在终端执行：`brew doctor`，应输出 "Your system is ready to brew."

---

## Xcode 环境

当前主机：macOS 27.2，Apple Silicon (arm64)。

**构建产物与模拟器分别定目标**：

| 项目 | 当前目标 |
|---|---|
| 上架或模拟上架的构建产物 | 支持 iOS >= 15.0，最低部署版本为 iOS 15.0 |
| 模拟器运行验证 | iPhone 12 + iOS 17；本机对应的已安装 runtime 为 iOS 17.0.1 |
| 命令行工具链 | `/Applications/Xcode.app` 的 Xcode 27.2 |
| 构建入口 | `PresetApp.xcworkspace` |

构建 SDK、最低部署版本与模拟器运行系统是三个独立概念。使用新版 SDK 或
在 iOS 17 模拟器测试，不表示产物最低版本应提高到 iOS 17。业务代码需要支持
最低版本 iOS 15.0；更高版本专属 API 必须有可用性检查和兼容路径。
iOS 17 模拟器测试不等于已完成 iOS 15 真机或 runtime 的实际运行兼容性验证。

“模拟上架”在本文指 Release / Archive 构建流程验证，不代表正式签名、导出、
上传或 App Store 审核已经完成。模拟器产物与真机发行产物分别构建。

**配置现状与待完成项**：

- 工程与本地 package 仍是此前配置的 iOS 15.5；本轮环境验证沿用该配置。
- 后续需将 Project / Target 的 Debug / Release 四处 `IPHONEOS_DEPLOYMENT_TARGET`
  统一为 `15.0`，并将 `PresetDeviceInfo/Package.swift` 改为 `.iOS("15.0")`，
  才能按新基线验收产物，不能把当前 15.5 配置表述为已覆盖 iOS 15.0。
- 2026-11-14 已通过 Xcode 27.2 的 Debug / Release 模拟器完整构建、iPhone 12 / iOS 17.0.1 安装和启动；业务流程验证进度见下方本轮记录。
- SDK 可用、runtime 被识别、模拟器能启动、App 完整构建并运行须分别验收。

**工具链约定**：

- 使用命令行的 `xcodebuild`、`xcrun simctl`，不要求 Xcode IDE 能打开。
- 每条命令显式设置 `DEVELOPER_DIR`，避免依赖全局 `xcode-select` 状态。
- 2026-11-14 检查时 `/Applications/Xcode15.app` 已不存在；当前验证仅使用 Xcode 27.2。
- Xcode 12.5.1 已删除，不再使用 `/Applications/Xcode12.app`。
- 工程从 `PresetApp.xcworkspace` 构建。workspace 同时引用 App 工程和本地
  `PresetDeviceInfo` package，不能依据单独构建 `.xcodeproj` 的 package 缺失错误修改依赖结构。
- 不因工具链问题改变 RootShell、Stage、Page、Navigation 架构。

**构建产物验收**：

配置统一为 15.0 后，检查有效 build settings，并验证 Release 归档流程。
下面的无签名归档用于模拟上架，不执行上传：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp -showBuildSettings

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/PresetApp-release-check.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive
```

不能只检查 build settings；归档成功后还需确认产物的 `MinimumOSVersion` 为
`15.0`，并按正式发行需要单独验证签名与导出。

**模拟器验收**：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list runtimes
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
```

优先复用已有的 iPhone 12 / iOS 17 设备。没有合适设备时再创建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl create 'iPhone 12 - iOS 17' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-12 \
  com.apple.CoreSimulator.SimRuntime.iOS-17-0
```

本机 runtime 的显示名称为 iOS 17.0，实际系统版本为 17.0.1；使用标识
`com.apple.CoreSimulator.SimRuntime.iOS-17-0`。创建成功后记录设备 UDID，
再按 UDID 执行启动、定向构建、安装、App 启动与业务流程验证。

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
  -configuration Debug -destination 'platform=iOS Simulator,id=<UDID>' \
  CODE_SIGNING_ALLOWED=NO build
```

### 本轮验证：macOS 27.2 / Xcode 27.2 / iPhone 12 / iOS 17（2026-11-14）

复用已有设备，未新建设备或清空模拟器数据：

| 检查项 | 实测结果 |
|---|---|
| 主机 | macOS 27.2（26B123），arm64 |
| 工具链 | `/Applications/Xcode.app`，Xcode 27.2（27B52），Swift 6.4.2 |
| 首次启动组件检查 | `xcodebuild -checkFirstLaunchStatus` 通过 |
| runtime | iOS 17.0.1（21A342），标识 `com.apple.CoreSimulator.SimRuntime.iOS-17-0`，available |
| 设备 | iPhone 12，UDID `EB5976BB-75ED-4038-9B5E-686708B05E4A` |
| 启动 | 首次 `simctl boot` 返回连接错误；后续 `bootstatus -b` 启动成功，迁移完成，约 21 秒 |
| Debug 模拟器构建 | workspace 完整构建成功，退出码 0，约 54.1 秒 |
| Release 模拟器构建 | workspace 完整构建成功，退出码 0，约 22.4 秒 |
| 安装、启动 | Debug App 的 `simctl install`、`simctl launch` 均成功；首次 App PID 为 56852 |
| 再次冷启动 | 对同一设备执行 shutdown、boot、bootstatus、App launch 均退出码 0，约 11.3 秒；App PID 为 59678 |
| Home / 网络 | Home 正常显示，设备和包信息可见；HTTP POST 返回 `https://httpbin.org/post` |
| Bill / Profile | Bill 打开、返回 Home、切换 Profile 均成功 |
| 登录页 | 全屏登录页可打开；空表单和仅用户名时禁用提交，两项均非空后允许提交 |
| 登录与持久化 | mock 登录成功，Profile 显示测试用户名；本地保存用户名与 UUID token，未发现密码字段 |
| 登录后杀进程重启 | terminate / launch 均成功，回到 Profile 后仍显示同一用户名和 Log Out |
| 登出 | 页面立即恢复 Log In；本地 token 和用户名均清除，重启后持久化文件仍不含两项数据 |
| 验收结论 | 2026-11-14 用户确认简单验收通过，结束本轮验证；未继续执行登出后重启的 Profile 界面确认、取消登录及其余页面检查 |
| 收尾 | 按用户要求关闭 iPhone 12 / iOS 17.0.1 模拟器，已确认状态为 Shutdown，保留设备及数据 |
| 产物最低版本 | 实测 `MinimumOSVersion = 15.5`，尚未达成文档要求的 15.0 |

本机 Xcode 27.2 的设备界面是
`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`（Device Hub），
可以显示并操作该模拟器；本机旧路径 `Contents/Developer/Applications/Simulator.app`
不存在。构建、安装和启动均通过命令行完成，未使用 Xcode IDE。

首次连接错误为 `NSPOSIXErrorDomain` code `53`，包含
`XPC error talking to SimLaunchHostService ... Connection invalid`。
后续同一设备启动成功；第二次关闭再启动也成功，未复现该连接错误。
这支持当前环境可用的判断，仍不代表已做长期稳定性或性能测试。

旧 iOS 13.7 / 14.5 runtime 注册项产生 `Malformed bundle does not contain an identifier`
警告，本轮未清理；这些警告未阻止本轮构建和运行。Debug / Release 均出现
`Metadata extraction skipped, no AppIntents.framework dependency found` 警告，未阻塞构建。
此前 Xcode 15.4 的 `AssetCatalogSimulatorAgent` 资源编译错误未在本轮 Xcode 27.2 构建复现。

本轮沿用工程最低版本 15.5，未修改业务源码、签名设置或全局 `xcode-select`。
Release 结果是模拟器构建，不代表真机 Release Archive、签名、导出或正式上架通过。
构建耗时仅为本次观测，不作为性能基准。

临时证据目录：`/tmp/preset-ios17-validation-20261114.rxfBcv`（可能被系统清理）：

- `debug-build.log`、`debug-build.xcresult`：Debug 完整构建日志和结果。
- `release-simulator-build.log`、`release-simulator-build.xcresult`：Release 模拟器构建结果。
- `simulator-boot.png`：启动后的系统桌面截图。
- `app-runtime.log`：统一日志查询结果，仅得到表头，未采集到应用日志条目；HTTP POST 成功依据是界面显示的结果。
- `second-cold-start.log`：同一设备再次冷启动及 App 重启的命令、输出和退出码。
- `login-persistence.json`、`logout-persistence.json`、`logout-relaunch-persistence.json`：持久化检查布尔结果，不记录 token 或密码。
- `session-relaunch.log`：登录后及登出后的终止、重启命令与退出码。

### 历史验证：iPhone 12 / iOS 15.5（2026-11-13）

以下保留旧目标的实测结果，不作为当前模拟器验收基线：

- 当时将 App 工程 Project / Target 的 Debug / Release 四处最低版本和本地
  `PresetDeviceInfo` package 统一为 iOS 15.5；该配置目前仍未调整到新目标 15.0。
- 使用 `/Applications/Xcode15.app` 的 Xcode 15.4（15F31d）、Swift 5.10、
  iOS / Simulator SDK 17.5。命令行工具和首次启动检查通过，不以 IDE 能否打开为条件。
- Apple 官方 iOS 15.5 runtime（19F70）镜像位于
  `/Users/shuaizhexu/Downloads/iOS_15.5_Simulator_Runtime.dmg`，大小为
  5,415,504,705 字节；`hdiutil verify` 通过，内含的 `iPhoneSimulatorSDK15_5.pkg`
  经 `pkgutil --check-signature` 确认为 `signed Apple Software`。
- 镜像属于旧式 HFS 安装镜像，不能用 `simctl runtime add` 直接导入。
  使用 `pkgutil --expand-full` 解包后，将未修改的 Payload 放到
  `/Users/shuaizhexu/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 15.5.simruntime`；
  未修改 runtime 版本、兼容性元数据或系统组件。
- `simctl list runtimes` 能识别 runtime，但状态为 `unavailable`，报告：

  ```text
  The iOS 15.5 simulator runtime is not supported on hosts after macOS 26.99.99.
  The iOS 15.5 simulator runtime is not supported on macOS 27.2.
  ```

- 创建 iPhone 12 / iOS 15.5 返回 `com.apple.CoreSimulator.SimError` code `401`。
  未取得目标设备 UDID，未执行该目标的启动、App 安装或业务流程验收。
  这是当前主机 CoreSimulator 的限制，换用旧版 Xcode 不能据此绕过。
- Xcode 15.4 的 workspace 无签名 Debug 模拟器构建进入 Swift 编译和链接，
  生成 arm64、x86_64 二进制，但资源编译失败，整体退出码为 `65`：

  ```text
  Assets.xcassets: error: Failed to launch AssetCatalogSimulatorAgent via CoreSimulator spawn
  Failed to handshake with platform tool
  AssetCatalogSimulatorAgent exited before we could handshake
  ```

- 资源编译错误在安装旧 runtime 前已出现，不能将部分编译成功记为完整 App 构建通过。
  临时构建日志为
  `/var/folders/cd/td6ysgds7w1d4n0hvdr6sjs40000gp/T/preset-ios155-build-qqru42_6/build.log`，
  可能被系统清理。
- workspace 已成功加载 `PresetDeviceInfo`，无需按单独构建 `.xcodeproj` 的
  `Missing package product` 错误修改 `packageReferences`。
- 当时未使用 iOS 17 代替 iOS 15.5 验收；现已将后续模拟器目标改为 iPhone 12 / iOS 17，
  该新目标的后续实测结果见上方 2026-11-14 记录。

---

## CocoaPods / Swift Package Manager 环境

**概念说明**：
- **CocoaPods** - 传统的 iOS 依赖管理工具，用于集成第三方库（如 `AFNetworking`、`SDWebImage` 等）
- **Swift Package Manager (SPM)** - Apple 官方依赖管理工具，Xcode 内置集成
- **Carthage** - 去中心化的依赖管理工具（可选，按需使用；本项目不采用）

**本项目结论**：
- 当前项目不引入第三方 UI/网络库，因此不需要新增 `Podfile`、`Package.swift` 或 SPM 依赖配置。
- CocoaPods / SPM 环境只作为基础开发环境检查项保留，方便后续需要第三方库时使用。
- 若本机曾经配置过国内镜像、Git 代理，或用系统 Ruby + `sudo gem install cocoapods` 安装过 CocoaPods，建议清理；若没有这些历史配置，则无需清理。

### CocoaPods

**规范要求**：
- 通过 Homebrew 提供的 Ruby（`ruby@3.1`）以非 sudo 的 `gem install` 方式安装，避免使用系统 Ruby + `sudo gem install`
- 依赖：先安装 Homebrew Ruby `brew install ruby@3.1`
- 安装命令：`gem install cocoapods`（在 Homebrew Ruby 环境下执行）

**检查步骤**：
1. 确认安装：`pod --version`，应为 1.15.x+
2. 确认命令来源：`which pod`，应返回 `/opt/homebrew/lib/ruby/gems/3.1.0/bin/pod`
3. 确认 Ruby 来源：`gem environment | grep 'RUBY EXECUTABLE'`，应为 `/opt/homebrew/opt/ruby@3.1/bin/ruby`
4. 确认主仓库初始化：`pod repo list`，应至少包含 `trunk`

**清理判断**：
- 若 `which pod` 指向 `/usr/bin/pod`、系统 Ruby 路径，或依赖 `sudo gem install`，应改为 Homebrew Ruby 环境重新安装。
- 若当前项目没有 Podfile，不需要执行 `pod install`，也不需要生成 `Pods/` 或 `Podfile.lock`。

### Swift Package Manager

**规范要求**：
- 随 Xcode 内置，无需单独安装
- 通过 Xcode 的 File > Add Package Dependencies 进行管理
- 项目级配置在 `Package.swift` 或 `.xcodeproj/project.pbxproj` 中

**检查步骤**：
1. 确认 swift 工具链：`swift --version`
2. 确认包管理器：`swift package --version`

**清理判断**：
- 若 `.xcodeproj/project.pbxproj` 中没有 SPM 依赖配置，不需要执行 `xcodebuild -resolvePackageDependencies`。
- 若后续移除 SPM 依赖，应同步清理 Xcode 项目中的 package references，避免留下不可解析的远程包。

---

## 镜像源设置

**概念说明**：
- **CocoaPods** - 通过 Podfile 中的 source 字段指定仓库源
- **Swift Package Manager** - 依赖仓库地址在项目中直接指定
- 镜像源应在项目级配置，确保配置可控且不影响其他项目

**本机网络现状**（已实测）：
- `cdn.cocoapods.org` 直连可用，无需配置国内镜像源
- GitHub 直连可用，SPM 无需配置代理
- 因此本机/本项目**不配置**任何镜像源或代理，使用官方默认源

### CocoaPods 源

**配置文件位置**：
- `<项目目录>/Podfile`

**规范要求**：
- 使用默认 CDN 源，不替换为国内镜像
- Podfile 中可不显式声明 source（默认即 CDN）

**默认源**：
```ruby
source 'https://cdn.cocoapods.org/'
```

**检查步骤**：
1. 确认 Podfile 未指向国内镜像（如清华、阿里云）
2. 确认本地仓库：`pod repo list`，应包含 `trunk` 且 URL 为 `https://cdn.cocoapods.org/`

**清理判断**：
- 若 Podfile 曾经写过国内镜像 source，应删除或改回 `https://cdn.cocoapods.org/`。
- 若本机 CocoaPods repo 指向非官方源，应移除后重新使用默认 trunk。

### Swift Package Manager

**配置位置**：
- 项目级：在 Xcode 的 File > Add Package Dependencies 中添加，配置写入 `.xcodeproj/project.pbxproj`

**规范要求**：
- 直接使用 GitHub 等官方仓库地址，不配置 Git 代理
- 全局 Git 配置（`~/.gitconfig`）不设置 `http.proxy` / `https.proxy`

**检查步骤**：
1. 确认无 Git 代理：`git config --global --get http.proxy`，应返回空
2. 确认 GitHub 连通性：`curl -I https://github.com`，应返回 `200`

**清理判断**：
- 若存在全局 Git 代理但本机网络已可直连 GitHub，应删除 `http.proxy` / `https.proxy`。
- 若项目中曾使用镜像仓库地址添加 SPM 依赖，应改回官方仓库地址。

---

## 基础 UI 组件选择

**规范要求**：
- 使用 SwiftUI 原生组件，**不引入第三方 UI 库**（无 CocoaPods/SPM 依赖）。
- 列表式界面用 `List` + `Section`（原生 `<ul>/<li>` 等价物），配合 `GroupedListStyle()` 实现分组卡片外观。
- 状态信息（如 Network、Device）与日志列表统一收纳进同一个 `List` 的不同 `Section`，避免裸 `ScrollView` + `Text` 的简陋排版。

**坑点（已实测）**：
- 在 Xcode 12.5.1 / Swift 5.4 下，`.listStyle(.grouped)` 会报 `cannot infer contextual base in reference to member 'grouped'`（`.grouped` 成员推断失败）；**改用显式构造 `.listStyle(GroupedListStyle())` 即可通过编译**。
- `GroupedListStyle` 自 iOS 13 起可用，覆盖当前 iOS 15.0 最低部署目标；本项目统一用 `GroupedListStyle()`，避免在 Xcode 12.5.1 / Swift 5.4 下触发样式推断问题。

**示例**：
```swift
List {
    Section(header: Text("Network")) { Text(statusText) }
    Section(header: Text("Device")) {
        Text("IDFA: \(info.idfa)")
        Text("IDFV: \(info.idfv)")
    }
    Section(header: Text("Log")) {
        ForEach(logs.indices, id: \.self) { Text(logs[$0]) }
    }
}
.listStyle(GroupedListStyle())
```

---

## Info.plist 与构建设置变量

**概念**：
- `Info.plist` 中形如 `$(VARIABLE_NAME)` 的写法**不是宏**（非 C 预处理器），而是 Xcode 构建系统的**构建设置变量引用**（build setting variable expansion）。
- 构建时由构建系统把 `$(...)` 用对应 build setting 的值替换，再把**已替换好的具体字符串**写入最终 `.app/Info.plist`；运行时 `Bundle.main` 读到的是具体值，看不到 `$(...)`。

**本仓库实际取值**（`PresetApp/Info.plist` + `project.pbxproj` build settings）：
| plist key | plist 原值 | 构建期解析结果 | 运行时读取方式 |
|---|---|---|---|
| `CFBundleDisplayName`/`CFBundleName` | `$(PRODUCT_NAME)` | `PresetApp` | `Bundle.main.object(forInfoDictionaryKey:)` |
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | `com.lisitede.preset.app` | `Bundle.main.bundleIdentifier` |
| `CFBundleExecutable` | `$(EXECUTABLE_NAME)` | `PresetApp` | — |
| `CFBundlePackageType` | `$(PRODUCT_BUNDLE_PACKAGE_TYPE)` | `APPL` | — |
| `CFBundleShortVersionString` | `1.0`（字面量） | `1.0` | `object(forInfoDictionaryKey:)` |
| `CFBundleVersion` | `1`（字面量） | `1` | `object(forInfoDictionaryKey:)` |

**结论**：读取 App 包信息（名称/Bundle ID/版本号/构建号）应通过 `Bundle.main` 在运行时取解析后的值，无需关心 `$(...)` 形式；`PackageInfoHelper` 即依此实现。

---

## 网络层选择

**规范要求**：
- 使用原生 `URLSession`（Foundation 自带），**不引入第三方网络库**。
- 对应 Android 的 `OkHttp + Retrofit` 组合：`URLSession` ≈ OkHttp（传输层），`Codable` + `URLRequest` ≈ Retrofit（序列化/接口层）；本项目以 `HttpClient`（`URLSession` 单例）+ `HttpBinResponse`（`Codable`）实现。

**第三方生态（了解但不采用）**：
- **Alamofire** 是 iOS 最流行的第三方 HTTP 库（Swift，AFNetworking 的继任者），地位相当于 Android 的 OkHttp/Retrofit，提供更简洁的链式 API、上传/下载、重试、请求拦截等高级能力。
- 本项目按「不引入第三方 UI/网络库」规范，统一用原生 `URLSession`；若后续项目需要更复杂的网络栈再评估引入 Alamofire。

**async/await 支持现状（坑点）**：
- 历史 iOS 14 + Xcode 12.5.1 / Swift 5.4 基线不支持 Swift Concurrency。当前 iOS 15.0 + Xcode 27.2 目标基线已具备相应语言与运行时能力，但本次只调整兼容目标，现有网络层继续使用 completion handler，不在本轮重构。
- 故 `HttpClient.postTest(body:completion:)` 采用 **completion handler 回调风格**，不可写为 `async func`；回调内更新 SwiftUI `@State` 需在主线程，`HttpClient` 已用 `DispatchQueue.main.async` 派发 completion。
- 后续若单独安排 Swift Concurrency 重构，可再调整接口与调用方式；本次文档更新不改变现有 completion API。

**示例（当前 completion 风格）**：
```swift
HttpClient.shared.postTest(body: ["foo": "bar"]) { result in
    switch result {
    case .success(let resp): // 主线程
    case .failure(let err):  // 主线程
    }
}
```

---

## 运行时日志（命令行查看）

**背景**：
- App 经 `xcrun simctl launch` 启动，未接 Xcode 调试器；本项目使用命令行工具链而非 Xcode IDE，故无法用 Xcode 控制台看日志。
- 代码用 `os_log`（`OSLog`）输出，统一 subsystem 为 `com.lisitede.preset.app`，便于按 subsystem 精确过滤。例：`HttpClient` 的 category 为 `HttpClient`。

**实时流式日志**（按 subsystem 过滤，最常用）：
```bash
xcrun simctl spawn <UDID> log stream \
  --predicate 'subsystem == "com.lisitede.preset.app"' --level debug
```
> 旧 iOS 14.5 设备 UDID 已失效。当前目标为 iPhone 12 / iOS 17；设备 UDID 需查询或创建成功后记录，不能复用旧 UDID。

**按进程名过滤**（不看 subsystem 时）：
```bash
xcrun simctl spawn <UDID> log stream \
  --predicate 'processImagePath CONTAINS "PresetApp"' --level debug
```

**历史日志**（回看最近 N 时间）：
```bash
xcrun simctl spawn <UDID> log show --last 2m \
  --predicate 'subsystem == "com.lisitede.preset.app"' --level debug
```

**其他方式**：
- **Console.app**：左栏选模拟器设备，按进程 `PresetApp` 或 subsystem 过滤。
- `print()`/`NSLog` 输出同样进入统一日志，可用上述 `log stream` 抓取；但本项目统一用 `os_log`。

**坑点**：
- `os_log` 的格式串必须为**静态串**（StaticString），动态值用占位符传参，字符串默认在真机上会被脱敏（显示 `<private>`）；用 `%{public}@` 可强制公开。模拟器默认为 public，但仍建议显式写 `%{public}@`。
- `os.Logger`（结构体）需 iOS 14+；虽已满足当前最低兼容目标，但本项目仍统一用 `OSLog` + `os_log` 函数（iOS 10+），保持现有日志实现。

**HttpClient 日志示例**（实测输出）：
```
→ POST https://httpbin.org/post
  body {"foo":"bar","platform":"ios"}
← <响应体原文>
✗ decode <错误描述>   # 仅在解码失败时
```

---

## 状态管理：ViewModel vs ObservableObject

**背景**：Android 侧把首页状态与网络调用收进 `HomeViewModel : ViewModel`（`count` + `httpPostState` 两个 `StateFlow`，`sendPost` 在 `viewModelScope` 启协程）。iOS 是否需要对应改造，需先理清两者的差异。

**Android 引入 ViewModel 的硬痛点**：
1. **抗配置变更**：旋转屏幕会重建 Activity，`ViewModel` 不销毁，保住 `count`/`httpPostState` 不丢、请求不重发。
2. **协程生命周期**：`viewModelScope.launch` 绑定 ViewModel 生命周期，Activity 销毁自动取消，防泄漏/回调悬挂。
3. **单一数据源**：`StateFlow` 作为 UI 唯一观察源，加载/成功/错误统一建模为 `HttpPostState`。

**iOS 对应物与差异**：
| Android | iOS 对应 | 说明 |
|---|---|---|
| `ViewModel` | `ObservableObject` | 持有状态与逻辑的引用类型 |
| `StateFlow`/`MutableStateFlow` | `@Published` 属性 | UI 自动订阅刷新 |
| View 持有 ViewModel | `@StateObject`（首次创建并随视图生命周期保留） | `@ObservedObject` 不负责创建 |
| `viewModelScope.launch` | completion handler（当前）/ `Task`（iOS 15+） | 无作用域泄漏问题 |
| `withContext(Dispatchers.IO)` | `URLSession` 默认后台队列 | `HttpClient` 已主线程派发回调 |

**结论（是否必须改造）**：
- **非强制**：SwiftUI 的 `@State` 由框架持有，根视图旋转/重渲染不丢状态；用 completion handler 无协程作用域泄漏——Android 的两大硬痛点在 iOS 不成立。
- **但建议对齐**：为架构一致与可测试性，把 `httpLoading/httpResult`（及若补上的 `count`）与 `sendPost` 收进 `HomeViewModel: ObservableObject`，`ContentView` 用 `@StateObject` 观察，View 退化为纯渲染层，与 Android 一一对应。
- **注意**：`@StateObject` 需 iOS 14+，被当前 iOS 15.0 最低部署目标覆盖，可作为后续 ViewModel 改造的标准持有方式。

**当前 iOS 实现（未改造）**：状态散落在 `ContentView` 的 `@State`，`sendHttpPost()` 直接调 `APIClient.shared.postTest` 并在 completion 内更新 `@State`。

---

## 签名与设备设置

### 已确认方案

- 使用普通 Apple ID 提供的免费 `Personal Team`，不购买 Apple Developer Program。
- 免费 Personal Team 可以为本人连接的 iPhone 创建开发证书和 provisioning profile，并安装开发测试包。
- 免费签名不支持 App Store、TestFlight 和正式分发，部分高级 entitlement 不可用；当前项目使用的 UIKit、SwiftUI、网络、UserDefaults、ATT/IDFA 不构成已知阻碍。
- 免费 provisioning 有效期较短，常见为 7 天；过期后需要重新构建和安装。
- Xcode 27.2 用于当前命令行构建与 iPhone 12 / iOS 17 模拟器验证；真机仍需匹配设备系统，首次配置 Apple ID 时才需要账户界面。
- 真机签名流程不得修改 RootShell、Controller、Stage、Page、Navigation 等架构，正式产物的 deployment target 按当前目标设为 iOS 15.0。
- 当前只记录方案，尚未执行 Apple ID 登录、证书申请、设备注册、签名或安装。

### 首次账户配置

首次配置账户时使用 `/Applications/Xcode.app` 的新版 Xcode：

1. 打开该 Xcode 的 `Settings > Accounts`。
2. 登录普通 Apple ID，确认出现 `Personal Team`。
3. 记录 Personal Team ID，后续通过命令行的 `DEVELOPMENT_TEAM` 临时传入。
4. 只配置 Xcode 的本机账户，不在项目 UI 中选择 Team，不把 Team ID 写入 `project.pbxproj`。

首次登录需要 Xcode 的账户界面；账户和签名材料建立后，构建、安装和启动都使用命令行。
`xcodebuild -allowProvisioningUpdates` 本身不能在没有任何 Xcode 账户的机器上首次登录 Apple ID。

### 真机准备

1. 使用 USB 连接 iPhone，并在 Mac 和 iPhone 上完成信任确认。
2. iOS 16+ 设备需要打开 Developer Mode，并按系统要求重启设备。
3. 确认当前 Xcode 支持真机系统版本；不支持时安装更新版 Xcode，不修改项目源码。
4. 查看设备和 UDID：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun devicectl list devices
```

### 命令行自动签名构建

在同一个 zsh 会话中设置任务专用变量：

```bash
PRESET_DEVICE_UDID='<真机 UDID>'
PRESET_PERSONAL_TEAM_ID='<Personal Team ID>'
PRESET_DEVICE_BUILD_DIR="$(mktemp -d /tmp/preset-device-build.XXXXXX)"
```

使用新版 Xcode、免费 Personal Team 和 Automatic Signing 构建：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
  -workspace PresetApp.xcworkspace \
  -scheme PresetApp \
  -configuration Debug \
  -destination "platform=iOS,id=$PRESET_DEVICE_UDID" \
  -derivedDataPath "$PRESET_DEVICE_BUILD_DIR" \
  DEVELOPMENT_TEAM="$PRESET_PERSONAL_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build
```

`DEVELOPMENT_TEAM` 和 `CODE_SIGN_STYLE` 只覆盖本次构建，不写入工程文件。构建前后执行
`git status --short`，应确认签名流程没有产生项目改动。

### 安装与启动

使用对应 Xcode 自带的 `devicectl` 安装已签名 App：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun devicectl device install app \
  --device "$PRESET_DEVICE_UDID" \
  "$PRESET_DEVICE_BUILD_DIR/Build/Products/Debug-iphoneos/PresetApp.app"
```

通过 Bundle ID 启动：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun devicectl device process launch \
  --device "$PRESET_DEVICE_UDID" \
  com.lisitede.preset.app
```

### 验证与排障

```bash
security find-identity -v -p codesigning
```

自动签名成功后，应至少看到一条可用的 Apple Development 签名身份。常见问题：

- `Signing requires a development team`：未传入 Personal Team ID。
- `No Accounts` 或 provisioning 更新失败：Apple ID 尚未添加到新版 Xcode Accounts。
- Bundle ID 注册失败：`com.lisitede.preset.app` 在该 Personal Team 下不可用，需要单独讨论 Bundle ID；不要顺带修改项目架构。
- 找不到 destination：设备未信任、Developer Mode 未开启，或当前 Xcode 不支持设备系统版本。
- App 数日后无法启动：免费 provisioning 已过期，重新执行签名构建和安装。
- 当前 `Info.plist` 仅声明竖屏，而 target 同时支持 iPhone/iPad；真机构建可能出现方向警告，但不阻塞 iPhone 安装。
