import SwiftUI

enum MainTab: Hashable {
    case play
    case achievements
    case settings
}

struct MainTabShellView: View {
    @State private var selectedTab: MainTab = .play

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .play:
                    NavigationStack {
                        HomeView()
                    }
                case .achievements:
                    NavigationStack {
                        AchievementsView()
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 24) {
            tabButton(icon: "play.circle.fill", label: "Play", tab: .play)
            tabButton(icon: "star.circle.fill", label: "Badges", tab: .achievements)
            tabButton(icon: "gearshape.fill", label: "Settings", tab: .settings)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appSurfaceColor)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(icon: String, label: String, tab: MainTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == tab ? .appPrimary : .appTextSecondary)
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

