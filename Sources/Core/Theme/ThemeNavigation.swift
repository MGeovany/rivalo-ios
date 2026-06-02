import SwiftUI
import UIKit

extension Theme {
    /// Applies brand fonts and dark chrome to UIKit navigation bars (SwiftUI `NavigationStack`).
    @MainActor
    static func configureNavigationBar() {
        let titleFont = uiFont(name: "Rajdhani-SemiBold", size: 20)
        let largeFont = uiFont(name: "Rajdhani-SemiBold", size: 32)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = uiColor(red: 4, green: 5, blue: 6)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.96, alpha: 1),
            .font: titleFont,
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(white: 0.96, alpha: 1),
            .font: largeFont,
        ]

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = uiColor(red: 1, green: 90 / 255, blue: 0)

        let tabFont = uiFont(name: "Rajdhani-Medium", size: 10)
        let tabAttrs: [NSAttributedString.Key: Any] = [.font: tabFont]
        UITabBarItem.appearance().setTitleTextAttributes(tabAttrs, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(tabAttrs, for: .selected)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = uiColor(red: 36, green: 37, blue: 38)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    private static func uiFont(name: String, size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }

    private static func uiColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

// MARK: - SwiftUI

/// Inline navigation title in Rajdhani, aligned with trailing toolbar actions.
struct RivalScreenTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.title(size: 20))
            .foregroundStyle(Theme.Colors.textPrimary)
    }
}

extension View {
    /// Brand navigation bar: inline title (Rajdhani) on the same row as toolbar buttons.
    func rivalNavigationChrome(title: String = "") -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !title.isEmpty {
                    ToolbarItem(placement: .principal) {
                        RivalScreenTitle(title: title)
                    }
                }
            }
    }
}
