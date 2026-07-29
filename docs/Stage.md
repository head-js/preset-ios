# iOS Page / Stage 架构

> [!WARNING]
> 本文档记录的是已被替换的早期 SwiftUI TabView
> 方案，不再作为当前实现规范。当前 Shell、MainStage、BottomNav 和 UIKit
> Page Stack 规范以 `docs/Controller.md` 为准。当前类型和文件固定命名为
> `RootShell` / `RootShell.swift` 与 `MainStage` / `MainStage.swift`。

## 背景

项目采用 Page-first 架构。

所有面向业务的屏幕都应该建模为 `Page`。
SwiftUI view、UIKit controller、tab、button、scene、window 等平台概念都是实现细节，除非架构上明确提升其语义。

本文档记录当前 iOS 侧的 Stage 落地方案。

当前阶段不引入 AppRouter，不自研导航框架。
Stage 之间的层级导航使用 UIKit 原生 `UINavigationController`。
Stage 内部的同层级 Page 切换使用 SwiftUI 实现。
`RootShell` 是普通 UIKit `UIViewController`，内部持有一个 child `UINavigationController`。
SwiftUI 不负责创建或管理 `UINavigationController`。

## 核心方向

```text
UIKit 管成熟导航栈
SwiftUI 管页面渲染
项目只定义 Page / Stage 的业务语义
```

在 iOS 14 部署目标下，成熟可控的导航栈能力来自 UIKit：

```text
UINavigationController
UIViewController
UIHostingController
```

因此，本期方案不是用 SwiftUI `NavigationView` 承担复杂架构核心，也不是自研导航框架。

最低兼容目标是 iPhone 12 + iOS 14。
本机模拟器验证使用 iPhone 12 + iOS 14.5 运行时。

## 术语

### Page

`Page` 是业务屏幕身份。

Page 是产品需求、导航语义、埋点、权限和架构讨论使用的单位。

示例：

```text
HomePage
WebViewPage
ProfilePage
PlanPage
PhasePage
TaskPage
```

`Page` 不等于任意 SwiftUI view。
一个 Page 可以用 SwiftUI、UIKit 或二者桥接实现，但业务身份仍然是 Page。

### Shell

`Shell` 是重型容器。

它表示 app 级或业务域级边界。Shell 可以承担较重的职责，例如：

```text
根组合
业务域边界
全局 chrome
safe-area 策略
window 级行为
高层生命周期
```

当前顶层模型：

```text
RootShell
```

`Shell` 不是 Page。

### Stage

`Stage` 是承载一组同层级 Page 的轻量容器。

Stage 可以被 `RootShell` 的导航栈承载，并通过 UIKit 原生 push/pop 进入或退出。
Stage 内部持有当前 active Page selection，并支持该 Stage 内 peer Pages 之间的流畅切换。

Stage 是非常轻量的概念。它只应该持有 Page 切换所需的状态，例如当前 active Page selection。
它不应该代替 Page 持有属于 Page 的业务状态或 UI 状态。

Stage 内部切换 UI 不是 Stage 定义的一部分，可以由以下入口驱动：

```text
BottomTab
LinkButton
Segmented control
自定义按钮组
手势
```

`Stage` 不是 Page。

### StageStack

`StageStack` 是 Stage 之间的层级导航栈。

本期不自研 `StageStack`，直接使用 UIKit 原生 `UINavigationController` 实现：

```text
RootShell = UIViewController
StageStack = RootShell 内部的 child UINavigationController
StageController = UIHostingController(StageView)
```

Stage 之间的进入/返回使用 UIKit 原生能力：

```text
pushViewController(...)
popViewController(...)
```

### Scene

`Scene` 是 iOS 系统生命周期概念，例如 `UIScene`、`UIWindowScene` 或 SwiftUI `Scene`。

在 iPhone 上，多数应用通常只有一个活跃 UI scene。
在本架构中，Scene 不是业务概念，也不作为 Page-first 的建模单位。

## 当前结构

```text
RootShell
  └─ RootShell: UIViewController
       └─ child UINavigationController / StageStack
            ├─ MainStage
            │    └─ MainStageView
            │         ├─ HomePage
            │         ├─ WebViewPage
            │         └─ ProfilePage
            │              └─ Goto Plan -> push PlanStage
            │
            └─ PlanStageController
                 └─ PlanStageView
                      ├─ PlanPage
                      ├─ PhasePage
                      └─ TaskPage
```

初始导航栈：

```text
[MainStage]
```

从 `ProfilePage` 点击 `Goto Plan` 后：

```text
[MainStage, PlanStageController]
```

返回时：

```text
popViewController()
=> [MainStage]
```

这里的关键边界是：

```text
MainStage -> PlanStage 是 UIKit push
PlanPage -> PhasePage / TaskPage 是 PlanStage 内部 peer Page 切换
```

`PlanStage` 不是 `MainStage` 的某个 tab。
`MainStage` 与 `PlanStage` 也不是并列同时显示。
`RootShell` 显示的是 UIKit navigation stack 的栈顶 Stage。
`UINavigationController` 由 `RootShell` 作为 child controller 持有，不应塞进 SwiftUI view 中管理。

## 当前落地调整

当前代码中的 `ContentView` 仍然是 demo 聚合视图，用于集中验证网络、设备信息、包信息、HTTP、WebView 等能力。
它还不是本文档定义的 `RootShell`。

当前形态可以理解为：

```text
ContentView
  ├─ Network demo
  ├─ App info demo
  ├─ Device info demo
  ├─ HTTP demo
  └─ WebView demo
```

本次架构落地时，应将入口调整为 UIKit RootShell，并拆出 Stage 与 Page 层级：

```text
RootShell
  └─ child UINavigationController
       ├─ MainStage
       │    └─ MainStageView
       │         ├─ HomePageView
       │         ├─ WebViewPageView
       │         └─ ProfilePageView
       │
       └─ PlanStageController
            └─ PlanStageView
                 ├─ PlanPageView
                 ├─ PhasePageView
                 └─ TaskPageView
```

调整目标：

```text
ContentView 不再承担 demo 聚合职责。
RootShell 是普通 UIViewController，承担 RootShell。
RootShell 以 child controller 方式持有 UINavigationController。
UINavigationController 承担 StageStack。
MainStage 承担 MainStage 的 UIKit 承载。
PlanStageController 承担 PlanStage 的 UIKit 承载。
MainStageView / PlanStageView 使用 SwiftUI 渲染 Stage 内容。
各 PageView 承担对应 Page 的 UI 实现。
```

原 `ContentView` 中已有的 demo 能力可以迁移到具体 Page 中，但不能继续作为顶层聚合结构。
其中 WebView 应迁移到 `WebViewPage`，不继续放在 `HomePage`。

## MainStage

`MainStage` 是 root Stage。

它包含：

```text
HomePage
WebViewPage
ProfilePage
```

`MainStage` 使用 SwiftUI 的底部 tab 形态实现。

概念上：

```text
MainStage
  持有当前 active main Page selection
  使用 BottomTab / TabView 作为切换 UI
```

底部 tab 入口映射到 Page：

```text
HomeTab    -> HomePage
WebViewTab -> WebViewPage
ProfileTab -> ProfilePage
```

tab 本身不是 Page。
它只是改变 `MainStage` 当前 active Page 的入口。

`ProfilePage` 可以提供 `Goto Plan` 入口。
该入口不在 `MainStage` 内部切换 Page，而是触发外层 UIKit navigation stack：

```text
ProfilePage
  -> onGotoPlan()
  -> pushViewController(PlanStageController)
```

这里的 `onGotoPlan` 可以先用闭包或 delegate 接出。
这只是把 SwiftUI 事件接到 UIKit 原生导航栈，不是 AppRouter，也不是自研导航框架。

## PlanStage

`PlanStage` 是被 UIKit navigation stack push 出来的 Stage。

它包含：

```text
PlanPage
PhasePage
TaskPage
```

`PlanStage` 使用页面内容区域中的 LinkButton 形态实现切换。

概念上：

```text
PlanStage
  持有当前 active plan Page selection
  使用 LinkButton 作为切换 UI
```

LinkButton 在同一个 Stage 内切换 active Page：

```text
PlanPage  -> PhasePage
PlanPage  -> TaskPage
PhasePage -> PlanPage
TaskPage  -> PlanPage
```

这些转换是同层级 Page 切换。
它们不应该被建模为 UIKit push，也不应该被建模为层级 Page 导航。

## 状态保留策略

`MainStage` 与 `PlanStage` 有意采用两种不同实现，用于演示两类状态保留问题。

### Stage 之间的状态保留

Stage 之间使用 UIKit `UINavigationController`。

当 `PlanStageController` 被 push 到 `MainStage` 之上时，`MainStage` 仍保留在 UIKit navigation stack 中。
因此，返回时可以自然回到原来的 `MainStage`。

这比简单的 `switch activeStage` 更符合当前需求：

```text
MainStage(ProfilePage)
  -> push PlanStage
  -> pop
  -> 回到原 MainStage
```

### MainStage 状态保留

`MainStage` 使用 SwiftUI `TabView` / BottomTab 形态。

`TabView` 通常更接近天然的 tab 状态保留模型：tab 切换时，各 tab 内容更容易保持在稳定的容器结构中。
因此 `HomePage`、`WebViewPage`、`ProfilePage` 内部的局部状态、滚动位置等通常更容易保留。

但这不是无条件保证。状态是否稳定仍然取决于：

```text
view identity 是否稳定
是否主动改变 .id(...)
Page 状态是否由 Page 自己或对应 view model 持有
容器是否重建
```

`WebViewPage` 需要特别注意 UIKit/WebKit 实例状态。
`WebViewHelper`、`WKWebView` 或类似持有真实 UIKit/WebKit 实例的对象，不应该由会频繁重建的 SwiftUI view 临时创建。
这类对象应该由 `WebViewPage` 对应的稳定 view model、controller 或明确的 model holder 持有，并注入到 `WebViewPageView`。

否则切换 Page 或重建 view 时，WebView 可能重新加载，导致页面历史、滚动位置、加载进度、JS 上下文等状态丢失。

### PlanStage 状态保留

`PlanStage` 使用页面内容区域中的 LinkButton 驱动 Page 切换。

LinkButton 只是切换入口，本身不提供状态保留能力。
如果 `PlanStage` 采用 `activePage` + `switch` 的方式只渲染当前 Page，那么非 active Page 可能会从视图树中移除，并在下次进入时重建。

这会影响有内部状态的页面，例如：

```text
表单输入
滚动位置
WebView 状态
临时编辑内容
异步加载中间态
```

因此，`PlanPage`、`PhasePage`、`TaskPage` 如果需要跨切换保留状态，不应该把属于 Page 的状态提升到 `PlanStage`。
这些状态应该由 Page 自己或对应的稳定 view model 持有。

如果需要保留完整 Page 状态，优先选择让三个 Page 同时挂载在后台，由 `PlanStage` 控制显示隐藏。
也就是说，保留的是完整 Page，而不是只保留一份从 Page 中抽离出来的脱水状态。
但当前设计保留 LinkButton + active Page 切换方式，目的就是显式暴露并演示这种状态管理问题。

## 同层级 Page 切换

同一个 Stage 内的 peer Pages 应该流畅切换，并始终留在同一个轻量容器内。

允许的模型：

```text
MainStage.currentPage = home
MainStage.currentPage = webView
MainStage.currentPage = profile

PlanStage.currentPage = plan
PlanStage.currentPage = phase
PlanStage.currentPage = task
```

不要把同层级 Page 切换建模成层级导航：

```text
HomePage -> push WebViewPage -> push ProfilePage
PlanPage -> push PhasePage -> push TaskPage
```

这些结构暗示了更深一层的导航和返回栈语义，而当前需求是同层级 Page 切换。

## 需要避免的重型切换

Android 中不适合为了高频同层级 Page 切换而创建新的 Activity，因为 Activity 是重型容器。

iOS 中最接近、也应该避免的场景包括：

```text
创建新的 UIWindow 或 UIWindowScene
反复替换 window root
重建整套 root controller 层级
每次同层级 Page 切换都创建新的 navigation/tab controller 树
用 modal presentation 承载同层级高频 Page 切换
```

对于同一个 Stage 内的 peer Pages，应该留在 Stage 内切换。
对于 Stage 之间的层级进入/返回，应该使用 UIKit 原生 navigation stack。

## 可行性检查

该方案符合当前约束：

```text
iOS 14 可用：UINavigationController、UIViewController、UIHostingController、SwiftUI TabView 均可用。
最低兼容目标为 iPhone 12 + iOS 14。
当前模拟器验证环境为 iPhone 12 + iOS 14.5。
不依赖 iOS 16 NavigationStack / NavigationPath。
不需要自研导航栈。
不需要本期引入 AppRouter。
Stage 之间的 push/pop 交给 UIKit。
Stage 内部 peer Page 切换交给 SwiftUI。
iOS 15+ API 必须使用 #available 守卫，并提供 iOS 14 兼容路径。
```

主要注意点：

```text
SwiftUI 事件需要通过闭包或 delegate 接到 UIKit controller。
Stage 不应该持有 Page 的业务状态或 UI 状态。
Page 状态应由 Page 自己或 Page 对应的 view model 持有。
如果 Page 状态必须跨切换完整保留，应保留完整 Page，而不是把 Page 状态脱水到 Stage。
PlanStage 的 LinkButton + activePage 设计用于演示状态重建问题，不默认解决所有状态保留。
WebViewHelper / WKWebView 这类 UIKit/WebKit 实例状态，应由 WebViewPage 的稳定 view model、controller 或明确的 model holder 持有。
```

### iOS 14 写法约束

由于最低部署目标是 iOS 14，落地时应确保所有基础路径可在 iOS 14 运行：

```text
当前项目入口继续使用 AppDelegate + UIWindow。
AppDelegate 创建 UIWindow，并将 RootShell 设置为 window.rootViewController。
本期不新增 SceneDelegate，不启用 Scene manifest，避免引入多入口复杂度。
当前项目继续使用 UIKit AppDelegate 生命周期，保持 UIWindow 和根控制器切换逻辑集中。
StageStack 使用 UIKit UINavigationController，不使用 SwiftUI NavigationStack / NavigationPath。
Stage 使用 UIHostingController 承载 SwiftUI StageView。
需要稳定对象时，由 MainStage、PlanStageController、PageModelHolder 或其他明确 owner 创建并持有。
稳定对象包括 Page view model、WebViewHelper、WKWebView wrapper、异步加载 model 等。
SwiftUI view 不负责创建这些稳定对象，只通过构造参数接收。
如果稳定对象实现 ObservableObject，SwiftUI view 使用 @ObservedObject 接收。
如果稳定对象只是普通引用，SwiftUI view 使用普通 let 引用接收。
可以使用 iOS 14 提供的 @StateObject；需要由 UIKit 控制生命周期的对象仍由 controller 或明确的 model holder 持有。
SwiftUI 组件和 modifier 需要逐项确认 iOS 14 可用。
iOS 15+ API 必须使用 #available 守卫，并提供 iOS 14 兼容路径。
```

## 设计规则

```text
Shell = 重型边界
Stage = 轻量 peer Page 容器，可被 RootShell 的 UIKit navigation stack 承载
Page  = 业务屏幕身份
```

规则：

```text
RootShell 由普通 UIViewController 实现。
RootShell 以 child controller 方式持有 UINavigationController。
UINavigationController 承担 StageStack。
Stage 之间的层级进入/返回使用 pushViewController / popViewController。
Stage 持有 peer Pages。
Stage 只持有 active Page selection state。
Stage 不持有属于 Page 的状态。
Page 持有自己的状态，或交给 Page 对应的 view model 持有。
Stage 的内部切换 UI 可以替换。
BottomTab 不是 Page。
LinkButton 不是 Page。
SwiftUI view identity 不是业务 Page identity。
同层级 Page 切换应该留在当前 Stage 内完成。
需要保留 Page 状态时，优先保留完整 Page 在后台，而不是把 Page 脱水成 Stage 状态。
```

当前决策：

```text
RootShell 使用普通 UIViewController。
RootShell 内部持有 child UINavigationController。
MainStage 是 root Stage。
PlanStage 从 ProfilePage 触发并通过 UIKit push 进入。
MainStage 使用 BottomTab / TabView。
PlanStage 使用页面内容区域中的 LinkButton。
LoginPage 和 SplashPage 暂不在本文档讨论范围内。
本期不实现 AppRouter。
本期不自研导航框架。
```
