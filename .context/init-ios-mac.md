# 在 macOS 上初始化 iPhone 开发环境

> updated_by: Codex
> updated_at: 2026-07-29 00:00:00+08:00
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

**规范要求**：
- 必须安装可正常打开的新版 Xcode；当前为 Xcode 15.0.1，安装路径为 `/Applications/Xcode.app`，附带 iOS 17 SDK
- 必须安装 Command Line Tools
- 另需旧版 Xcode 12.5.1，安装路径为 `/Applications/Xcode12.app`，用于 iOS 14.5 模拟器和最低兼容工具链验证
- Xcode 12.5.1 GUI 因当前 macOS 兼容问题不可用，但其命令行工具链可以正常编译
- 新版 Xcode 用于较新 iOS SDK 的真机构建、免费 Personal Team 自动签名和设备安装
- 切换工具链只使用单条命令的 `DEVELOPER_DIR`，不通过修改工程架构或源码适配不同 Xcode

**检查步骤**：
1. 确认 Xcode 安装路径：检查 `/Applications/Xcode.app` 是否存在
2. 确认新版：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version`，当前应为 15.0.1
3. 确认旧版：`DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer xcodebuild -version`，应为 12.5.1
4. 确认 Command Line Tools：`xcode-select -p`，应返回 `/Applications/Xcode.app/Contents/Developer` 或 `/Library/Developer/CommandLineTools`
5. 确认新版 iOS SDK：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -showsdks`，应列出 `iphonesimulator` 与 `iphoneos`
6. 确认模拟器列表：`DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer xcrun simctl list devices available`

**环境变量要求**：
- `DEVELOPER_DIR`：本项目有两个 Xcode，必须在构建命令中显式指定，避免依赖全局 `xcode-select` 状态
- iOS 14.5 模拟器验证使用：`DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer`
- iOS 17 SDK / 真机签名使用：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`

**检查步骤**：
1. 确认指定工具链：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find xcodebuild`
2. 确认旧版工具链：`DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer xcrun --find xcodebuild`

**双工具链结论**：

```text
Xcode 12.5.1 + iOS 14.5 Simulator
→ 验证最低版本、Swift 5.4 和现有兼容写法

Xcode 15.0.1 + iOS 17 SDK
→ 构建 arm64 真机包、签名、安装和启动
```

使用新版 SDK 构建不会改变 `IPHONEOS_DEPLOYMENT_TARGET = 14.0`，也不会改变
RootShell、Stage、Page、Navigation 等项目架构。若真机系统高于当前 Xcode 15.0.1
支持范围，应安装与真机系统匹配的更新版 Xcode，并只切换 `DEVELOPER_DIR`。

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
- `GroupedListStyle` 自 iOS 13 起可用，覆盖当前 iOS 14 最低兼容目标；本项目统一用 `GroupedListStyle()`，避免在 Xcode 12.5.1 / Swift 5.4 下触发样式推断问题。

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
- Swift `async/await` 需 **Swift 5.5+ 且运行时 iOS 15+**；本项目最低兼容目标 iOS 14 + Xcode 12.5.1 / Swift 5.4 **不支持**，编译会报 `async` 相关错误。
- 故 `HttpClient.postTest(body:completion:)` 采用 **completion handler 回调风格**，不可写为 `async func`；回调内更新 SwiftUI `@State` 需在主线程，`HttpClient` 已用 `DispatchQueue.main.async` 派发 completion。
- 升级路径：若未来最低兼容目标提至 iOS 15+ 并改用 Xcode 13+/Swift 5.5+，可重构为 `func postTest(body:) async throws -> HttpBinResponse`，调用处用 `Task { ... }` 或 SwiftUI `.task` 修饰符。

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
- App 经 `xcrun simctl launch` 启动，未接 Xcode 调试器；且 Xcode 12 GUI 因兼容性问题**不可用**（仅其命令行工具链 `DEVELOPER_DIR=.../Xcode12.app/Contents/Developer` 可用于编译），故无法用 Xcode 控制台看日志。
- 代码用 `os_log`（`OSLog`）输出，统一 subsystem 为 `com.lisitede.preset.app`，便于按 subsystem 精确过滤。例：`HttpClient` 的 category 为 `HttpClient`。

**实时流式日志**（按 subsystem 过滤，最常用）：
```bash
xcrun simctl spawn <UDID> log stream \
  --predicate 'subsystem == "com.lisitede.preset.app"' --level debug
```
> 本机验证设备 UDID = `C624713C-5298-4322-9F5E-D35531DF32DF`（iPhone 12 / iOS 14.5）。

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
- `os.Logger`（结构体）需 iOS 14+；虽已满足当前最低兼容目标，但本项目仍统一用 `OSLog` + `os_log` 函数（iOS 10+），与现有 Xcode 12.5.1 / Swift 5.4 实现保持一致。

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
- **注意**：`@StateObject` 需 iOS 14+，与本项目最低兼容目标 iOS 14 对齐，可作为后续 ViewModel 改造的标准持有方式。

**当前 iOS 实现（未改造）**：状态散落在 `ContentView` 的 `@State`，`sendHttpPost()` 直接调 `APIClient.shared.postTest` 并在 completion 内更新 `@State`。

---

## 签名与设备设置

### 已确认方案

- 使用普通 Apple ID 提供的免费 `Personal Team`，不购买 Apple Developer Program。
- 免费 Personal Team 可以为本人连接的 iPhone 创建开发证书和 provisioning profile，并安装开发测试包。
- 免费签名不支持 App Store、TestFlight 和正式分发，部分高级 entitlement 不可用；当前项目使用的 UIKit、SwiftUI、网络、UserDefaults、ATT/IDFA 不构成已知阻碍。
- 免费 provisioning 有效期较短，常见为 7 天；过期后需要重新构建和安装。
- Xcode 12.5.1 只负责最低兼容开发与模拟器验证；真机使用可正常打开的 Xcode 15.0.1 或与设备系统匹配的更新版本。
- 真机签名流程不得修改 RootShell、Controller、Stage、Page、Navigation 等架构，也不提高 iOS 14.0 deployment target。
- 当前只记录方案，尚未执行 Apple ID 登录、证书申请、设备注册、签名或安装。

### 首次账户配置

Xcode 12.5.1 的 GUI 不可用，因此使用 `/Applications/Xcode.app` 的新版 Xcode：

1. 打开 Xcode 15 的 `Settings > Accounts`。
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

使用 Xcode 15 自带的 `devicectl` 安装已签名 App：

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
