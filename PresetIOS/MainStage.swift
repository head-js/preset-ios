import SwiftUI

struct MainStage: View {
    enum Page: Hashable {
        case home
        case webView
        case profile
    }

    let dependencies: MainStageDependencies
    let onGotoPlan: () -> Void

    @State private var activePage: Page = .home

    var body: some View {
        TabView(selection: $activePage) {
            HomePage(dependencies: dependencies)
                .tabItem { Text("Home") }
                .tag(Page.home)

            WebViewPage(helperBox: dependencies.webViewHelper)
                .tabItem { Text("Web") }
                .tag(Page.webView)

            ProfilePage(onGotoPlan: onGotoPlan)
                .tabItem { Text("Profile") }
                .tag(Page.profile)
        }
    }
}
