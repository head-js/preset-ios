# preset-ios

## Roadmap

这是一个验证 iOS 开发能力范围的功能型项目。Roadmap 按 iOS 侧实际能力组织，每个 git 提交代表一个已完成的功能点。

### 基础设施 (Infrastructure)
- [x] 初始化 iOS 应用项目
- [ ] 配置 Schemes 多渠道构建

### 网络层 (Networking)
- [x] URLSession 集成
- [x] HttpClient 网络请求框架
- [x] ConnectivityHelper 网络连接检测

### 设备信息 (Device Info)
- [x] DeviceIdentityRepository 设备标识仓库
- [x] DeviceInfoRepository 设备信息仓库
- [x] DeviceInfoRepository 模块化为独立库
- [x] AppInfoRepository 应用包信息获取

### 状态与本地会话 (State & Local Session)
- [x] SwiftUI `@State` 页面状态管理
- [x] TokenStorage 本地持久化
- [x] Mock 登录 Token 与会话恢复

### 架构与导航 (Architecture & Navigation)
- [x] Page / Stage 页面组织
- [x] UIKit UINavigationController Stage 导航
- [ ] SwiftUI Navigation 导航组件

### 路由 (Routing)
- [ ] 路由框架集成
- [ ] PageRouter 页面路由

### UI 组件 (UI Components)
- [x] WebViewHelper WebView 封装组件
- [x] UIKit `UITabBarController` 底部导航栏
- [x] Home / Bill / WebView / Profile 底部导航项
- [ ] ProfileCard 个人信息卡片
- [ ] Lottie 动画卡片
- [ ] 动态化卡片组件

### 页面 (Pages)
- [x] LaunchScreen / SplashScreen 启动流程
- [x] ProfilePage / LoginPage Mock 登录流程
- [x] PlanPage 计划页面
- [x] BillPage 账单页面栈导航
- [ ] Privacy Agreement 隐私协议页面

### 第三方服务 (Third-party Services)
- [ ] AppsFlyerHelper 数据分析与归因

### 里程碑 (Milestones)
- [ ] ios/skills 验证完成
