# 当前任务：Profile 登录状态与 TokenStorage

## 目标

在 `ProfilePage` 增加一个仅作用于 Profile 的本地 mock 登录流程：

- 未登录时显示登录按钮。
- 点击登录按钮后使用 `fullScreenCover` 打开 `LoginPage`。
- 任意非空用户名和密码均可登录成功。
- 登录成功后在 `ProfilePage` 显示用户名和登出按钮。
- 关闭或杀死 App 后重新打开，仍保持登录状态。
- 登出后清除本地 token 和用户名。

本任务不实现真实网络登录，不影响其他业务页面。

## 平台约束

- 最低兼容目标：iPhone 12 + iOS 14。
- 本机验证环境：iPhone 12 + iOS 14.5 模拟器。
- 必须使用 Xcode 12.5.1 / Swift 5.4 构建。
- 不使用 iOS 15+ API。
- 不使用 Swift Concurrency、Observation 框架或 iOS 17 的 `@Observable`。

## 已确认决策

```text
状态管理        SwiftUI @State
持久化组件名    TokenStorage
持久化介质      iOS 系统轻量键值持久化存储
登录页面展示    fullScreenCover
Mock token      登录成功时生成 UUID
登录判断        token 存在
密码保存        不保存
路由守卫        不实现
ViewModel        不引入
ObservableObject 不引入
StateObject      不引入
SQLite           不使用
Keychain         不使用
```

`TokenStorage` 是业务组件名。其底层使用 Foundation 提供的系统键值持久化能力，但该实现细节不暴露到页面命名和业务接口中。

## 范围边界

本次登录能力只属于 `ProfilePage`：

- App 始终按现有启动流程进入 `MainStage`。
- 不根据登录状态替换 `window.rootViewController`。
- 不新增 `AuthShell`、`AuthStage` 或全局 `AppRouter`。
- 不修改 Home、WebView、Plan、Phase、Task 等其他业务页面。
- 不实现页面访问限制、token 过期、token 刷新或服务端校验。
- `LoginPage` 的展示和关闭由 `ProfilePage` 自己管理。

这里的“只修改 ProfilePage”是指只改变 Profile 业务流程。允许新增 `LoginPage`、`TokenStorage` 及必要的 Xcode 文件引用，但不改动其他页面行为和现有导航结构。

## 组件设计

### TokenStorage

`TokenStorage` 参考 Android `SharedPreferences` 版本的职责，只负责 token 和 username 的持久化，不负责 UI 状态通知。

建议接口：

```swift
final class TokenStorage {
    func saveToken(_ token: String, username: String)
    func getToken() -> String?
    func getUsername() -> String?
    func clear()
    func isLoggedIn() -> Bool
}
```

持久化键与 Android 侧保持一致：

```text
auth_token
auth_username
```

行为约束：

- `saveToken` 同时保存 token 和 username。
- `isLoggedIn` 以 token 是否存在为判断依据。
- `clear` 同时移除 token 和 username。
- 密码永远不传入 `TokenStorage`。
- 如果 token 存在但 username 缺失或为空，视为无效本地数据并清除，页面按未登录展示。

### ProfilePage

`ProfilePage` 使用本地 `@State` 保存页面展示所需的状态：

```text
username: String?
isLoginPresented: Bool
```

页面出现时从 `TokenStorage` 重新读取状态：

```text
token 和 username 均有效
  -> username 写入 @State
  -> 展示 Username 和 Log Out

没有 token 或本地数据无效
  -> username = nil
  -> 展示 Log In
```

已登录状态使用普通 label/value 行展示：

```text
Username    alice
Log Out
```

未登录状态：

```text
Log In
```

登出流程：

```text
点击 Log Out
  -> TokenStorage.clear()
  -> username = nil
  -> SwiftUI 自动刷新为未登录状态
```

### LoginPage

`LoginPage` 使用本地 `@State` 保存表单输入：

```text
usernameInput: String
passwordInput: String
```

页面包含：

- 用户名输入框。
- 密码 `SecureField`。
- 登录按钮。
- 取消或关闭按钮。

用户名和密码均非空时允许提交；不校验账号内容是否正确。

登录成功流程：

```text
点击 Log In
  -> 生成 UUID 字符串作为 mock token
  -> 回调 ProfilePage
  -> ProfilePage 调用 TokenStorage.saveToken(token, username)
  -> ProfilePage 更新 @State username
  -> isLoginPresented = false
  -> 返回 ProfilePage 并显示用户名
```

密码只存在于 `LoginPage` 的内存 `@State` 中，关闭页面后不再保留。

## fullScreenCover

`fullScreenCover` 是 iOS 14 可用的 SwiftUI 全屏模态展示能力。

```text
ProfilePage
  -> isLoginPresented = true
  -> fullScreenCover 展示 LoginPage
  -> 登录成功或取消
  -> isLoginPresented = false
  -> 回到原 ProfilePage
```

它不修改现有 `UINavigationController` 导航栈，不替换根页面，也不需要路由守卫。由于它不自动提供返回按钮，`LoginPage` 必须提供取消或关闭入口。

## 状态与持久化分工

```text
@State
  负责当前页面内存状态和触发 SwiftUI 刷新

TokenStorage
  负责跨 App 进程生命周期保存 token 和 username
```

`@State` 本身不会在 App 被杀死后保留。重新启动后的登录恢复来自 `TokenStorage`，`ProfilePage` 出现时再把持久化结果加载到 `@State`。

本任务没有多个独立页面共同观察登录状态的需求，因此不使用 `ObservableObject`、`@Published` 或 `@StateObject`。

## 数据流

```text
App 启动并进入 ProfilePage
  -> TokenStorage 读取 token / username
  -> 写入 ProfilePage @State
  -> 渲染登录或未登录状态

ProfilePage 打开 LoginPage
  -> LoginPage @State 保存表单输入
  -> UUID 生成 mock token
  -> ProfilePage 保存 TokenStorage
  -> 更新 ProfilePage @State
  -> 关闭 LoginPage

ProfilePage 登出
  -> TokenStorage 清除数据
  -> 清空 ProfilePage @State
```

## 建议变更范围

```text
PresetApp/ProfilePage.swift        修改 Profile UI、@State 和 fullScreenCover
PresetApp/LoginPage.swift          新增 mock 登录表单
PresetApp/TokenStorage.swift       新增 token/username 持久化组件
PresetApp.xcodeproj/project.pbxproj 添加新 Swift 文件到 PresetApp target
```

不修改：

```text
AppDelegate.swift
RootShellController.swift
MainStageController.swift
MainStage.swift
其他 Page / Stage
```

## 验收标准

1. 首次启动或无 token 时，Profile 显示 `Log In`。
2. 点击 `Log In` 后全屏打开 `LoginPage`。
3. 用户名或密码为空时不能提交。
4. 任意非空用户名和密码均登录成功。
5. 登录成功时生成 UUID 字符串作为 mock token。
6. Profile 使用普通 label/value 形式显示当前用户名。
7. Profile 显示可用的 `Log Out` 按钮。
8. 密码未写入任何持久化存储。
9. 杀死 App 后重新打开，Profile 仍显示已登录用户名。
10. 登出后 Profile 立即恢复为未登录状态。
11. 登出后杀死并重新打开 App，仍保持未登录。
12. token 存在但 username 无效时不崩溃，清除异常数据并按未登录处理。
13. LoginPage 可以取消并返回 Profile，且不会产生登录数据。
14. 使用 Xcode 12.5.1 在 iPhone 12 / iOS 14.5 模拟器构建和运行通过。
