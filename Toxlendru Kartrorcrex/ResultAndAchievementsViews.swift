import SwiftUI

struct GameResult {
    let stars: Int
    let time: TimeInterval
    let accuracy: Double
    let unlockedAchievementNames: [String]
}

struct ResultScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager

    let identifier: LevelIdentifier
    let difficulty: GameDifficulty
    let result: GameResult
    let onNextLevel: (() -> Void)?
    let onRetry: (() -> Void)?

    @State private var shownStars: Int = 0
    @State private var showBanner: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Stage Complete")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimaryColor)

                        HStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { index in
                                StarView(isFilled: index < shownStars)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: index < shownStars ? .appAccent.opacity(0.8) : .clear,
                                            radius: index < shownStars ? 12 : 0)
                                    .scaleEffect(index < shownStars ? 1.0 : 0.6)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7),
                                               value: shownStars)
                            }
                        }
                    }

                    statsSection

                    buttonsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 80)
                .padding(.bottom, 32)
            }

            if showBanner, let first = result.unlockedAchievementNames.first {
                AchievementBannerView(title: "New Badge Unlocked", message: first)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onAppear {
            playAnimations()
        }
        .navigationBarBackButtonHidden(true)
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack {
                statItem(title: "Time", value: formatted(time: result.time))
                statItem(title: "Accuracy", value: "\(Int(result.accuracy * 100))%")
            }
            HStack {
                statItem(title: "Stars", value: "\(result.stars)/3")
                statItem(title: "Best", value: "\(storage.bestStars(for: identifier))★")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSurface)
        )
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondaryColor)
            Text(value)
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            if let onNextLevel {
                Button(action: onNextLevel) {
                    Text("Next Level")
                        .font(.headline)
                        .foregroundColor(.appTextPrimaryColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.appPrimaryColor))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(ScaledButtonStyle())
            }

            if let onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.headline)
                        .foregroundColor(.appTextPrimaryColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.appSurface))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.appAccentColor.opacity(0.6), lineWidth: 1)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(ScaledButtonStyle())
            }

            Button {
                dismiss()
            } label: {
                Text("Back to Levels")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appTextSecondaryColor)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(ScaledButtonStyle())
        }
    }

    private func playAnimations() {
        shownStars = 0

        for i in 0..<min(result.stars, 3) {
            let delay = Double(i) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    shownStars = i + 1
                }
            }
        }

        if !result.unlockedAchievementNames.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showBanner = true
                }
            }
        }
    }

    private func formatted(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

struct StarView: View {
    let isFilled: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let starPath = StarShape(points: 5)
                .path(in: CGRect(x: 0, y: 0, width: size, height: size))

            ZStack {
                if isFilled {
                    starPath
                        .fill(Color.appAccent)
                    starPath
                        .stroke(Color.appSurface.opacity(0.8), lineWidth: 2)
                } else {
                    starPath
                        .stroke(Color.appTextSecondary, lineWidth: 1.5)
                }
            }
        }
    }
}

struct StarShape: Shape {
    let points: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.45

        var angle = -CGFloat.pi / 2
        let angleIncrement = .pi / CGFloat(points)

        var firstPoint = true

        for _ in 0..<(points * 2) {
            let radius = firstPoint ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if path.isEmpty {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }

            angle += angleIncrement
            firstPoint.toggle()
        }

        path.closeSubpath()
        return path
    }
}

struct AchievementBannerView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
            Text(message)
                .font(.caption)
                .foregroundColor(.appTextSecondaryColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSurfaceColor)
                .shadow(color: .appAccentColor.opacity(0.7), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct AchievementsView: View {
    @EnvironmentObject private var storage: AppStorageManager

    struct AchievementItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let isUnlocked: Bool
        let group: String
    }

    private var items: [AchievementItem] {
        [
            AchievementItem(title: "First Steps",
                            description: "Complete any level for the first time.",
                            isUnlocked: storage.hasAchievementFirstSteps,
                            group: "Progress"),
            AchievementItem(title: "Star Collector",
                            description: "Earn at least 30 stars across all stages.",
                            isUnlocked: storage.hasAchievementStarCollector,
                            group: "Progress"),
            AchievementItem(title: "Marathon Mode",
                            description: "Stay in activities for 30 minutes total.",
                            isUnlocked: storage.hasAchievementMarathon,
                            group: "Endurance"),
            AchievementItem(title: "Dedicated Player",
                            description: "Finish at least 50 activity runs.",
                            isUnlocked: storage.hasAchievementDedicated,
                            group: "Endurance"),
            AchievementItem(title: "First Perfect",
                            description: "Finish any level with three stars.",
                            isUnlocked: storage.hasAchievementFirstPerfect,
                            group: "Skill"),
            AchievementItem(title: "Perfect Collector",
                            description: "Earn three stars on at least ten levels.",
                            isUnlocked: storage.hasAchievementPerfectCollector,
                            group: "Skill"),
            AchievementItem(title: "Easy Explorer",
                            description: "Clear five easy levels with at least one star.",
                            isUnlocked: storage.hasAchievementEasyExplorer,
                            group: "Explorer"),
            AchievementItem(title: "Normal Explorer",
                            description: "Clear five normal levels with at least one star.",
                            isUnlocked: storage.hasAchievementNormalExplorer,
                            group: "Explorer"),
            AchievementItem(title: "Hard Explorer",
                            description: "Clear three hard levels with at least one star.",
                            isUnlocked: storage.hasAchievementHardExplorer,
                            group: "Explorer"),
            AchievementItem(title: "Quest Master",
                            description: "Complete all nine levels in any activity.",
                            isUnlocked: storage.hasAchievementQuestMaster,
                            group: "Mastery"),
            AchievementItem(title: "Speed Runner",
                            description: "Beat any level in under fifteen seconds.",
                            isUnlocked: storage.hasAchievementSpeedRunner,
                            group: "Speed"),
            AchievementItem(title: "Accuracy Lover",
                            description: "Reach at least ninety-five percent accuracy on any level.",
                            isUnlocked: storage.hasAchievementAccuracyLover,
                            group: "Skill")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !unlockedItems.isEmpty {
                    sectionHeader("Unlocked")
                    ForEach(unlockedItems) { item in
                        achievementRow(item)
                    }
                }

                if !lockedItems.isEmpty {
                    sectionHeader("Locked")
                    ForEach(lockedItems) { item in
                        achievementRow(item)
                    }
                }

                if storage.completedLevelsCount == 0 {
                    Text("Play a level to start unlocking badges.")
                        .font(.footnote)
                        .foregroundColor(.appTextSecondaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
        .navigationTitle("Badges")
        .toolbarBackground(Color.appBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var unlockedItems: [AchievementItem] {
        items.filter { $0.isUnlocked }
    }

    private var lockedItems: [AchievementItem] {
        items.filter { !$0.isUnlocked }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appTextSecondaryColor)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func achievementRow(_ item: AchievementItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.isUnlocked ? Color.appPrimaryColor : Color.appSurfaceColor)
                    .frame(width: 44, height: 44)
                Image(systemName: item.isUnlocked ? "checkmark.seal.fill" : "seal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(item.isUnlocked ? .appBackground : .appTextSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimaryColor)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondaryColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.group)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.appAccentColor)
                Image(systemName: item.isUnlocked ? "star.fill" : "star")
                    .foregroundColor(.appAccentColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSurface)
        )
    }
}

