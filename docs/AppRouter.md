# iOS AppRouter 架构

## 背景

项目采用 Page-first 架构。

研发心智应该始终是从 Page 导航到 Page：

```text
Navigate from Page to Page
```

`Stage`、`Stack`、`Shell`、`NavigationStack`、`TabView`、`UINavigationController`、手势等都属于 Router 底层需要解析和执行的实现细节。

本文档记录 AppRouter 的建模方向。

当前阶段只讨论架构边界，不要求本期实现 AppRouter，也不要求本期自研导航框架。

## 核心原则

```text
业务研发只感知 Page。
业务研发不感知 Stage。
业务研发不感知 Stack。
业务研发不感知平台导航容器。
```

所有会改变当前业务 Page 的行为，都应该被建模为对 AppRouter 的导航意图。

导航意图的来源可以是：

```text
Button tap
Bottom tab tap
Link button tap
Deep link
Push notification
系统 back 手势
自定义手势
登录态变化
启动恢复
```

这些入口最终都应该进入同一个 Router 语义层。

## AppRouter

`AppRouter` 是全局 Page 导航入口。

对业务层来说，它暴露的是 Page-first API：

```swift
router.navigate(to: .home)
router.navigate(to: .task)
router.navigate(to: .taskDetail(id: taskID))
router.back()
router.reset(to: .login)
```

业务层不应该直接操作：

```text
Stage.currentPage
NavigationStack.path
TabView.selection
UINavigationController
sheet / fullScreenCover state
```

这些状态可以存在，但应该是 Router 解析后的执行结果。

## Page Identity

Page 是业务屏幕身份。

示例：

```swift
enum AppPage: Hashable {
    case splash
    case login

    case home
    case tab2
    case tab3

    case plan
    case phase
    case task
    case taskDetail(id: String)
}
```

`AppPage` 不等于 SwiftUI view 类型，也不等于 UIKit controller 类型。

`AppPage` 是业务语义、导航语义、埋点、权限和恢复状态使用的身份。

## Router Topology

Router 内部需要知道 Page 所在的导航拓扑。

示例：

```text
home       -> RootShell / MainStage
tab2       -> RootShell / MainStage
tab3       -> RootShell / MainStage

plan       -> RootShell / PlanStage
phase      -> RootShell / PlanStage
task       -> RootShell / PlanStage
taskDetail -> RootShell / PlanStage / TaskStack

login      -> AuthShell
splash     -> LaunchShell
```

业务研发不需要知道这些映射。

这些映射用于 Router 判断一次 Page 到 Page 的导航应该被执行为：

```text
同 Stage peer Page 切换
Stack push
Stack pop
Stack popTo
Shell switch
Root reset
Modal present
Modal dismiss
```

## Stage 与 Router

`Stage` 是承载一组 peer Pages 的轻量容器。

从业务层看：

```swift
router.navigate(to: .task)
```

从 Router 内部看：

```text
当前 Page = plan
目标 Page = task

plan 和 task 属于同一个 PlanStage
=> 不 push
=> 不 modal
=> 不替换 root
=> PlanStage.activePage = task
```

因此，Stage 是 Router 的底层拓扑结构，不是业务研发需要直接操作的概念。

## Stack

`Stack` 用于表达层级导航。

Stage 和 Stack 解决的问题不同：

```text
Stage = peer Page 容器
Stack = hierarchical Page 容器
```

示例：

```text
PlanPage <-> PhasePage <-> TaskPage
```

这是同层级 Page 切换，应该由 Stage 执行。

```text
TaskPage -> TaskDetailPage
```

这是层级导航，应该由 Stack 执行。

业务层仍然只写：

```swift
router.navigate(to: .taskDetail(id: taskID))
```

Router 内部判断它应该是 Stack push。

## Route Planning

AppRouter 可以拆成 plan 和 execute 两层。

概念上：

```swift
func navigate(to target: AppPage) {
    let operations = planner.plan(from: currentPage, to: target)
    executor.apply(operations)
}
```

Route operation 示例：

```swift
enum RouteOperation {
    case switchShell(ShellID)
    case switchStagePage(StageID, AppPage)
    case push(StackID, AppPage)
    case pop(StackID)
    case popTo(StackID, AppPage)
    case resetStack(StackID, root: AppPage)
    case present(AppPage)
    case dismiss
}
```

示例：

```text
plan -> task
= [.switchStagePage(stage: .plan, page: .task)]

task -> taskDetail
= [.push(stack: .task, page: .taskDetail)]

taskDetail -> home
= [
  .popTo(stack: .task, page: .task),
  .switchStagePage(stage: .main, page: .home)
]

login -> home
= [
  .switchShell(shell: .root),
  .switchStagePage(stage: .main, page: .home)
]
```

## Back

`back` 不应该简单等同于某个底层 `path.removeLast()`。

Router 应该按当前拓扑和 Page policy 判断 back 行为。

建议优先级：

```text
1. 当前有 modal
   => dismiss

2. 当前 active Page 所在 Stack 可以 pop
   => pop

3. 当前 Page 有业务定义的返回目标
   => navigate(to: fallbackPage)

4. 当前 Shell 可以回到上一个 Shell
   => switch 或 reset Shell

5. 无可处理 back
   => 忽略或交给系统
```

同层级 Page 切换是否进入 back history，需要由 Stage policy 决定。

示例：

```text
MainStage
  底部 tab 语义
  peer switch 通常不进入 back history

PlanStage
  如果是流程语义，可以进入 back history
  如果只是同级页面切换，可以不进入 back history
```

## Edge Back Gesture

屏幕边缘划入的 back 手势也应该被视为导航意图来源。

它不应该绕过 Router 直接修改底层 Stack。

概念上：

```text
edge back gesture
=> router.back()
```

Router 需要提供能力判断：

```swift
router.canStartBackGesture
router.back()
```

是否允许 back 手势应该由 Page policy 决定。

示例：

```swift
struct PageNavigationPolicy {
    var allowsBackGesture: Bool
    var allowsBackButton: Bool
    var backBehavior: BackBehavior
}

enum BackBehavior {
    case pop
    case dismiss
    case navigate(AppPage)
    case confirmBeforeLeaving
    case disabled
}
```

示例策略：

```text
TaskDetailPage
  允许 back gesture
  back = pop

LoginPage
  禁用 back gesture
  back = disabled

PaymentPage
  禁用 back gesture
  back = confirmBeforeLeaving

EditPage
  禁用 back gesture
  back button 可以弹确认框
```

在 UIKit `UINavigationController` 中，可以通过 `interactivePopGestureRecognizer` 控制系统边缘返回手势。

在 SwiftUI `NavigationStack` / `NavigationView` 中，没有一个干净、稳定、官方的只禁用边缘返回手势的 API。若需要严格控制，Router executor 需要桥接底层 `UINavigationController`，或者使用自定义 Stack 容器。

## 三方库

AppRouter 这一层不建议直接交给三方库。

原因是本项目的核心抽象是 Page-first，全局 Router 需要理解：

```text
Page identity
Page topology
Shell
Stage
Stack
Back policy
Gesture policy
业务权限
登录态
Deep link
```

三方库可以作为底层 executor 的实现细节，但不应该替代 AppRouter 的业务语义层。

可考虑的方向：

```text
Apple NavigationStack
  适合作为现代 SwiftUI stack executor

Point-Free Swift Navigation
  思想接近 enum state driven navigation
  可作为状态建模参考

FlowStacks
  适合复杂 SwiftUI stack / deep link 场景
  可作为 stack executor 参考
```

无论是否使用三方库，业务 API 都应该保持：

```text
Navigate from Page to Page
```

而不是：

```text
Operate NavigationStack / TabView / Stage directly
```

## 当前决策

当前阶段只记录 AppRouter 的架构方向。

本期不实现 AppRouter。

本期不自研导航框架。

本期 Stage 讨论不需要覆盖 Navigate 问题。

本期重点仍然是明确：

```text
Page 是业务屏幕身份。
Stage 是同层级 Page 的轻量容器。
AppRouter 是未来统一 Page-to-Page 导航入口。
Stack、手势、平台导航容器都是 Router 底层实现细节。
```
