# iOS Controller / Page / Container 架构

## 背景

本文档记录项目在讨论 `Controller`、`Page`、`MainStage`、BottomNav、Navigation、module 与源码目录时确认的结论。

当前固定约束：

```text
BottomNav 使用 UIKit。
Navigation 使用 UIKit。
Page Stack 使用 UIKit。
具体页面内容可以使用 SwiftUI。
Page 是业务侧定义，不由继承关系决定。
正常情况下，Page 必须属于 App module。
```

本轮只讨论主流程，暂不讨论独立 modal。BottomNav 当前写死为 Home、Bill、WebView、Profile 四项，不使用 CustomTabBar，也暂不处理后端动态下发。

最低兼容目标仍为 iOS 14，本机验证工具链为 Xcode 12.5.1。

## 三个不同层次

架构讨论必须区分业务语义、UIKit 容器关系和页面渲染。

```text
业务语义
├── RootShell
├── MainStage
├── HomePage
├── BillPage
├── WebViewPage
└── ProfilePage

UIKit 容器关系
├── UIViewController
├── UINavigationController
├── UITabBarController
└── UIHostingController

页面渲染
└── SwiftUI View / UIKit View
```

业务概念不能通过 UIKit 继承关系反推。

例如 `HomePage` 和 `BillPage` 都是业务 Page，但在 UIKit Controller 树中的位置可以不同：

```text
HomePage -> MainStage 的 child controller
BillPage -> UINavigationController 的 stack controller
```

二者放置方式不同，不改变它们的 Page 身份。

## Page

`Page` 是业务侧定义的屏幕单元。

示例：

```text
HomePage
BillPage
WebViewPage
ProfilePage
PlanPage
TaskPage
```

Page 可以：

```text
作为 BottomNav 的内容
通过 Navigation push 进入
通过 modal 展示
被 Stage 承载
使用 SwiftUI 实现内容
使用 UIKit 实现内容
```

这些技术选择都不决定它是否是 Page。

以下推论是错误的：

```text
只有进入 UINavigationController 栈的对象才能叫 Page。
Page 必须继承 UIViewController。
SwiftUI View 不能代表 Page 内容。
```

正确方向是先由业务定义 Page，再为当前平台容器选择合适实现。

## Controller

`UIViewController` 不是任意布局节点，也不等于 Web 中的 `div`。

它是 iOS 系统和 UIKit 容器管理界面的标准单元。

一个 Controller 通常拥有一棵根 View 树：

```text
UIViewController
└── view
    ├── label
    ├── button
    ├── list
    └── 其他 view
```

普通布局节点更接近 `UIView` 或 SwiftUI `View`。Controller 数量通常远少于 View 数量。

Controller 提供或参与的系统能力包括：

```text
viewDidLoad
viewWillAppear / viewDidAppear
viewWillDisappear / viewDidDisappear
parent / child controller containment
UINavigationController push / pop
UITabBarController child 管理
navigationItem
tabBarItem
状态栏与屏幕旋转协作
系统页面转场
```

现代 iOS 项目不应把 `Controller` 机械理解为传统 MVC 中承担全部业务控制逻辑的对象。

在本项目中，它首先表示：

> 一个可以参与 UIKit Shell、BottomNav 和 Navigation 结构的系统界面单元。

## Controller Tree 与 View Tree

UIKit 应用同时存在 Controller tree 和 View tree。

Controller tree 较粗：

```text
RootShell
├── child UINavigationController
│   └── MainStage
│       ├── HomePage
│       ├── Bill action UIViewController
│       ├── WebViewPage
│       └── ProfilePage
└── presented LoginPage（仅登录界面显示期间）
```

View tree 较细：

```text
HomePage.View
└── List
    ├── Network Section
    ├── App Section
    ├── Identity Section
    ├── Fingerprint Section
    └── HTTP Section
```

不应为每个 Row、Section、Card 或 Button 创建 Controller。

## Shell

`Shell` 是项目定义的应用级容器语义，不是 iOS 固定类型。

当前 RootShell 使用 UIKit 落地：

```text
RootShell: UIViewController
└── child UINavigationController
```

RootShell 负责承载主 Navigation 容器，并统一负责 LoginPage 这类跨 Stage
全屏模态页面的展示和关闭。具体 Page 只发出登录请求，不直接持有 LoginPage。

LoginPage 不进入 Navigation stack。展示期间，RootShell 是 UIKit 的
`presentingViewController`，LoginPage 由系统放在
`RootShell.presentedViewController` 中持有。当前只有 ProfilePage 的登录按钮会发出请求，
暂不实现路由守卫。

当前 ProfilePage 不通过 MainStage 透传登录请求。登录按钮位于已经显示的
`ProfilePage.View` 中；点击后先进入 ProfilePage Controller，再直接通过当前 View 所属
Window 查找 RootShell：

```swift
view.window?.rootViewController as? RootShell
```

这个查找依赖两条已经确认的结构约束：RootShell 是当前 UIWindow 的
`rootViewController`；请求发生时 ProfilePage 正显示在该 Window 中。可见按钮的同步点击
满足这两个条件，因此不需要遍历 `parent`，MainStage 也不参与登录请求。

`view.window` 在 Controller 尚未显示、已经移除或未挂载 UIWindow 的测试中可能是 `nil`。
因此这种直接查找用于当前可见按钮的即时请求，不应未经复核地挪到初始化过程或延迟异步回调中。

RootShell 不等于 `MainActivity`，也不等于 `UINavigationController`。

## MainStage

`MainStage` 是项目定义的主流程容器。

当前交互设计：

```text
MainStage
└── BottomNav
    ├── Home
    ├── Bill
    ├── WebView
    └── Profile
```

在 iOS 上，MainStage 使用 UIKit 标准 `UITabBarController` 实现：

```swift
final class MainStage: UITabBarController {
}
```

名称应该表达项目角色，不应该因为继承 `UITabBarController` 就命名为 `MainTabBarController`。

```text
MainStage = 项目架构名称
UITabBarController = 当前 iOS 实现
```

如果未来内部实现变化，`MainStage` 的业务名称不应随之变化。

这是已经确认并完成落地的命名：

```text
MainStage
MainStage.swift
```

## BottomNav

BottomNav 的业务所有权属于 MainStage。

MainStage 决定：

```text
BottomNav 的入口数量
入口顺序
入口标题与图标
默认选中项
当前选中项
Bill 的特殊点击行为
每个入口对应 peer Page 还是 navigation action
```

UIKit `UITabBarController` 通过以下属性接收 Tab 内容：

```swift
var viewControllers: [UIViewController]?
```

因此 MainStage 的真实 UIKit 结构是：

```text
MainStage: UITabBarController
├── HomePage
├── Bill action controller（内部普通 UIViewController，不是 Page）
├── WebViewPage
└── ProfilePage
```

Home、WebView、Profile 是三个可流畅切换的 peer Tab Page。

Bill 是特殊入口：

```text
Bill Tab item
-> 对应一个内部普通 UIViewController action controller
-> shouldSelect 拦截
-> 不选择 action controller
-> 通过外层 UINavigationController push BillPage
```

点击 Bill 前后：

```text
当前 Tab = Profile
Navigation stack = [MainStage]

点击 Bill
Navigation stack = [MainStage, BillPage]
当前 Tab 仍然 = Profile

返回
Navigation stack = [MainStage]
恢复 Profile
```

## PlanStage

`PlanStage` 承载 Plan 业务域内三个可流畅切换的 peer Page：

```text
PlanStage
├── PlanPage
├── PhasePage
└── TaskPage
```

在 iOS 上，PlanStage 使用隐藏系统 Tab Bar 的 `UITabBarController` 实现：

```swift
final class PlanStage: UITabBarController {
}
```

类型和文件必须分别命名为：

```text
PlanStage
PlanStage.swift
```

PlanStage 不需要额外的 `PlanStageController` 包装。它本身既是外层
`UINavigationController` 的一个 stack controller，也是 Plan、Phase、Task 三个
Page 的 UIKit 容器。

从 ProfilePage 点击 Goto Plan 后，MainStage 通过外层 Navigation Controller push
PlanStage：

```text
RootShell
└── UINavigationController.viewControllers
    ├── MainStage
    └── PlanStage
```

此时外层 Navigation stack 是：

```text
[MainStage, PlanStage]
```

PlanStage 内部的系统容器关系是：

```text
PlanStage.viewControllers = [PlanPage, PhasePage, TaskPage]
```

PlanStage 不显示 Tab Icon 或 BottomNav：

```swift
tabBar.isHidden = true
```

页面中的按钮通过修改 `selectedIndex` 切换 peer Page：

```text
PlanPage  -> PhasePage
PlanPage  -> TaskPage
PhasePage -> PlanPage
TaskPage  -> PlanPage
```

这些切换不会修改外层 Navigation stack。PlanStage 内部没有 Navigation stack，
不执行 push/pop，也不记录 History。PlanPage、PhasePage、TaskPage 作为三个稳定的
child controllers 由 PlanStage 持有。

Plan、Phase、Task 的标题配置属于各自 Page：

```swift
planPage.title = "Plan"
phasePage.title = "Phase"
taskPage.title = "Task"
```

外层 Navigation stack 的栈顶是 PlanStage，因此顶部 Navigation Bar 实际读取
`PlanStage.navigationItem.title`。PlanStage 切换 Page 后只负责使用当前 Page 声明
的标题：

```swift
selectedIndex = page.rawValue
navigationItem.title = selectedViewController?.title
```

需要区分：

```text
标题内容的声明与所有权 = Page
当前标题的选择与实际显示 = PlanStage.navigationItem
```

## tabBarItem 的所有权

`UITabBarItem` 不是 BottomNav 本身。

```text
UITabBar       = 实际底部栏
UITabBarItem   = 某个入口的标题、图标、badge 等描述
```

UIKit 将 `tabBarItem` 属性定义在每个 child `UIViewController` 上：

```swift
homePage.tabBarItem = UITabBarItem(...)
```

`UITabBarController` 收集 child controllers 的 `tabBarItem`，并显示到自己的 `tabBar` 中。

需要区分三件事：

```text
属性存放位置 = child controller
配置职责     = MainStage
实际显示管理 = MainStage.tabBar
```

HomePage 不应该在自己的初始化代码中决定 BottomNav 图标或顺序。

应该由 MainStage 配置：

```swift
let homePage = HomePage(...)

homePage.tabBarItem = UITabBarItem(
    title: "Home",
    image: UIImage(systemName: "house"),
    selectedImage: UIImage(systemName: "house.fill")
)
```

## HomePage 的 UIKit 边界

HomePage 是业务 Page，并且当前作为 MainStage 的真实 Tab 内容。

因为 MainStage 使用 `UITabBarController`，HomePage 在 UIKit 边界上需要是 `UIViewController`。

当前页面内容使用 SwiftUI，因此可实现为：

```swift
final class HomePage: UIHostingController<HomePage.View> {
}
```

`UIHostingController` 是一个内容由 SwiftUI View 提供的 `UIViewController`。

MainStage 可以直接组合 HomePage：

```swift
let homePage = HomePage()

viewControllers = [
    homePage,
    billEmptyController,
    webViewPage,
    profilePage
]
```

MainStage 不应再次执行：

```swift
UIHostingController(rootView: HomePage(...))
```

HomePage 自己封装当前的页面内容实现，MainStage 只组合 UIKit Page controllers。

## BillPage 与 HomePage

BillPage 最初拆分 Controller / View 是一次结构验证，不代表所有 Page 必须机械复制相同文件结构。

Controller 位置：

```text
HomePage -> MainStage.viewControllers
BillPage -> UINavigationController.viewControllers
```

业务身份：

```text
HomePage -> Page
BillPage -> Page
```

文件是否拆分应由复杂度决定。

简单 Page 可以只使用一个文件：

```text
BillPage.swift
```

较复杂 Page 可以拆分：

```text
HomePage/
├── HomePage.swift
└── HomePage+View.swift
```

其中 `HomePage+View.swift` 通过 `extension HomePage` 声明嵌套类型
`HomePage.View`。文件名中的 `+` 是 extension 文件的命名约定，不是 Swift
语法的一部分。

## Navigation 与 Page Stack

项目已明确：Navigation 与 Page Stack 使用 UIKit。

当前主结构：

```text
RootShell
└── UINavigationController
    └── [MainStage]
```

push BillPage 后：

```text
[MainStage, BillPage]
```

UIKit Page Stack 的标准操作包括：

```swift
pushViewController(...)
popViewController(...)
popToViewController(...)
popToRootViewController(...)
setViewControllers(...)
```

业务代码长期应通过 AppRouter 表达 Page 导航意图，而不是直接依赖上述 UIKit API。Router 内部负责将 Page 导航转换为 UIKit stack 操作。

Page-first Router 方向详见 `docs/AppRouter.md`。

## Swift、UIKit 与 SwiftUI

需要区分语言和框架：

```text
Swift   = 编程语言
UIKit   = Shell、Controller、BottomNav、Navigation、Page Stack
SwiftUI = 页面内容渲染
```

当前项目是 UIKit 管结构、SwiftUI 管内容的混合架构，不是纯 SwiftUI 导航架构。

## Dependency Injection

`dependency` 和 `dependency injection` 不是 iOS 专有概念，而是通用软件工程术语。

```text
dependency = 当前代码完成工作时需要使用的其他对象或能力
injection  = 由外部创建这些对象，再传给使用方
```

例如，某个 Page 需要调用 `APIClient`，可以称 `APIClient` 是该 Page 的
dependency。这只是描述两个对象之间的关系，不是 Swift 关键字，也不是一种变量类型。

下面是普通 Swift 构造器注入：

```swift
final class SomePage: UIViewController {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

如果对象由 Page 自己创建，则仍然存在使用关系，但不属于外部注入：

```swift
final class SomePage: UIViewController {
    private let apiClient = APIClient.shared
}
```

iOS、UIKit 和 SwiftUI 没有提供一个等同于 Spring `@Autowired` 的官方通用 DI
容器。Swift 项目通常优先使用普通初始化参数完成显式构造器注入。SwiftUI 的
`@Environment` / `@EnvironmentObject` 可用于沿 View tree 提供共享环境或状态，
但不应被机械用作所有 service 的注入容器。

iOS / Swift 生态存在以下第三方 DI 工具：

```text
Swinject
  经典容器式 DI，按类型注册和解析，接近传统 DI Container。

Factory
  使用属性包装器提供注册和注入能力，使用感受更接近注解注入。

Needle
  Uber 开源，面向较大型项目，强调生成代码、分层组件和编译期安全。

Resolver
  较早的属性包装器 DI 方案；其作者目前推荐使用 Factory。
```

项目地址：

- [Swinject](https://github.com/Swinject/Swinject)
- [Factory](https://github.com/hmlongco/Factory)
- [Needle](https://github.com/uber/needle)
- [Resolver](https://github.com/hmlongco/Resolver)

当前项目暂不引入 DI 框架。现阶段对象数量和组装关系较少，Page 自己拥有的对象
由 Page 创建；确实需要从外部提供的行为使用普通 Swift 初始化参数或闭包表达。
只有在出现大量可替换实现、复杂对象生命周期或成规模的测试替换需求后，才重新
评估是否引入 DI 工具。

## Target 与 Module

`target` 是 Xcode 的构建配置，决定编译哪些文件、链接哪些依赖、生成什么产品。

`module` 是 Swift 编译器的代码、名称和访问边界。

当前可以近似理解为：

```text
PresetApp target
-> PresetApp module
-> PresetApp.app
```

设备信息库：

```text
PresetDeviceInfo package target
-> PresetDeviceInfo module
-> 被 PresetApp import
```

同一个 module 内的代码默认是 `internal` 可见。

```swift
struct SomeType {
}
```

等价于：

```swift
internal struct SomeType {
}
```

只有跨 module 使用时才需要考虑 `public` API。

## Page 不能是独立 module

项目约束：正常情况下，Page 必须属于 App module。

```text
PresetApp module
├── Shell
├── MainStage
├── Router
├── APIClient
├── TokenStorage
└── Pages
    ├── HomePage
    ├── BillPage
    └── ProfilePage
```

这样 Page 可以直接使用 App module 内部的：

```text
APIClient
TokenStorage
ConnectivityHelper
AppRouter
其他 app 专属基础设施
```

不应为了每个 Page 创建独立 target 或 module，也不应为了文件重名问题将 Page 模块化。

适合独立 module 的通常是可复用、边界明确的底层能力，例如当前的 `PresetDeviceInfo`。

## 目录不是 namespace

Swift 源码目录只是工程组织结构，不形成 Swift namespace、module 或访问控制边界。

```text
PresetApp/HomePage/HomePage+View.swift
PresetApp/BillPage/BillPage+View.swift
```

二者仍然属于同一个：

```text
PresetApp module
```

目录不会像 Java/Kotlin package 一样自动进入类型全名。

真正的类型隔离可以由嵌套类型表达：

```swift
HomePage.View
BillPage.View
```

## Swift 文件名约束

Xcode 12.5.1 / Swift 编译器验证结果：同一个 Swift target 中，参与编译的 Swift 文件 basename 必须唯一。

以下结构无法编译：

```text
BillPage/View.swift
HomePage/View.swift
```

实际编译错误：

```text
filename "View.swift" used twice
filenames are used to distinguish private declarations
```

即使文件位于不同目录，目录也不会消除这个限制。

可用结构：

```text
BillPage/BillPage+View.swift
HomePage/HomePage+View.swift
ProfilePage/ProfilePage+View.swift
```

这里限制的是文件 basename，不是嵌套 Swift 类型名。

以下类型可以同时存在：

```swift
BillPage.View
HomePage.View
ProfilePage.View
```

## 文件与目录命名规范

目录负责聚合，文件名本身必须携带 Page 或业务语义，并在 `PresetApp` target 内唯一。

推荐：

```text
HomePage/
├── HomePage.swift
├── HomePage+View.swift
└── Components/
    ├── HomeNetworkSection.swift
    ├── HomeDeviceInfoSection.swift
    └── HomeHTTPSection.swift

ProfilePage/
├── ProfilePage.swift
├── ProfilePage+View.swift
└── Components/
    ├── ProfileHeader.swift
    └── ProfileLoginSection.swift
```

避免使用缺少业务语义的通用文件名：

```text
View.swift
State.swift
Model.swift
Section.swift
Row.swift
```

改用：

```text
HomePage+View.swift
HomeState.swift
HomeModel.swift
HomeNetworkSection.swift
HomeInfoRow.swift
```

目录的意义是帮助研发定位、聚合和维护代码，不是提供编译隔离。

## 已确认结论

```text
1. Page 是业务定义，与具体继承类型无关。
2. Shell、BottomNav、Navigation、Page Stack 使用 UIKit。
3. MainStage 是项目名称，UITabBarController 是当前实现。
4. MainStage 的类型和文件必须分别命名为 MainStage、MainStage.swift。
5. RootShell 的类型和文件必须分别命名为 RootShell、RootShell.swift。
6. BottomNav 的业务所有权属于 MainStage。
7. Home、WebView、Profile 是 MainStage 中三个可切换的 peer Page。
8. Bill 是 BottomNav action；BillPage 是 UINavigationController 的 stack controller。
9. UIKit 将 tabBarItem 属性存放在 child controller 上，但由 MainStage 配置。
10. Page 正常情况下属于 PresetApp module，不能按 Page 拆 module。
11. Swift 目录不是 namespace，也不提供访问控制。
12. 同一 target 内 Swift 文件 basename 必须唯一。
13. 文件是否拆分由 Page 复杂度决定，BillPage 演示不构成强制模板。
14. 文件名应携带 Page 或业务语义，目录只作为软组织边界。
15. 当前项目暂不引入 DI 框架，优先使用直接创建、初始化参数或闭包。
16. PlanStage 是项目名称，使用隐藏 Tab Bar 的 UITabBarController 实现。
17. PlanStage 持有 PlanPage、PhasePage、TaskPage 三个 peer Page。
18. PlanStage 内部没有 Navigation stack 和 History，只通过 selectedIndex 切换。
19. 外层 Navigation stack 进入 Plan 业务域后是 [MainStage, PlanStage]。
20. Page 声明自己的 title，Stage 使用当前 Page 的 title 更新容器标题。
21. RootShell 使用 UIKit，并统一 present 跨 Stage 的全屏 LoginPage。
22. LoginPage 不进入 Navigation stack；当前仅由 ProfilePage 精准请求，暂不实现路由守卫。
23. ProfilePage 通过当前 view.window 的 rootViewController 直接查找 RootShell，MainStage 不透传登录请求。
```
