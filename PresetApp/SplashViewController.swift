import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Image("SplashCircle")
                .resizable()
                .frame(width: 96, height: 96)
        }
    }
}

/// 应用进程启动后的可控 Splash 页面。
///
/// 系统 Launch Screen 使用浅蓝圆；本页面使用相同尺寸的深蓝圆，
/// 颜色变化用于验证系统画面已经交接给应用代码。
final class SplashViewController: UIHostingController<SplashView> {
    private let displayDuration: TimeInterval
    private let onFinished: () -> Void
    private var hasScheduledTransition = false

    init(
        displayDuration: TimeInterval = 2,
        onFinished: @escaping () -> Void
    ) {
        self.displayDuration = displayDuration
        self.onFinished = onFinished
        super.init(rootView: SplashView())
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasScheduledTransition else { return }
        hasScheduledTransition = true

        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            guard let self = self, self.viewIfLoaded?.window != nil else { return }
            self.onFinished()
        }
    }
}
