import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var selectedDifficulty: GameDifficulty = .easy

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                quickStatsSection
                journeySection
                difficultyChips
                activitiesSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
        .navigationTitle("Play")
        .toolbarBackground(Color.appBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mini Quest Adventures")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondaryColor)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.appAccentColor.opacity(0.3), .clear]),
                            center: .center,
                            startRadius: 4,
                            endRadius: 26
                        )
                    )
                    .frame(width: 52, height: 52)

                StarShape(points: 5)
                    .fill(Color.appAccentColor)
                    .frame(width: 24, height: 24)
            }
        }
    }

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "Stars", value: "\(storage.totalStarsEarned)", icon: "star.fill")
            statCard(title: "Levels", value: "\(storage.completedLevelsCount)", icon: "flag.fill")
            statCard(title: "Sessions", value: "\(storage.totalActivitiesPlayed)", icon: "gamecontroller.fill")
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.appTextSecondaryColor)

            Text(value)
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurfaceColor)
        )
    }

    private var difficultyChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose Difficulty")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)

            HStack(spacing: 8) {
                ForEach(GameDifficulty.allCases) { diff in
                    Button {
                        selectedDifficulty = diff
                    } label: {
                        Text(diff.displayName)
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule()
                                    .fill(selectedDifficulty == diff ? Color.appPrimaryColor : Color.appSurfaceColor)
                            )
                            .foregroundColor(selectedDifficulty == diff ? .appBackgroundColor : .appTextSecondaryColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(ScaledButtonStyle())
                }
            }
        }
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journey to next badge")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appTextPrimaryColor)

            ProgressView(value: min(nextBadgeProgress, 1.0)) {
                EmptyView()
            } currentValueLabel: {
                Text(nextBadgeLabel)
                    .font(.caption)
                    .foregroundColor(.appTextSecondaryColor)
            }
            .tint(.appAccentColor)
        }
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pick an Activity")
                    .font(.headline)
                    .foregroundColor(.appTextPrimaryColor)
                Spacer()
            }

            ForEach(ActivityKind.allCases) { kind in
                NavigationLink {
                    LevelGridView(activity: kind, difficulty: selectedDifficulty)
                } label: {
                    ActivityCardView(activity: kind, difficulty: selectedDifficulty)
                }
                .buttonStyle(ScaledButtonStyle())
            }
        }
    }

    private var subtitleText: String {
        if storage.completedLevelsCount == 0 {
            return "Start with a short quest today."
        } else {
            return "Continue your journey and chase new stars."
        }
    }

    private var nextBadgeProgress: Double {
        // ориентируемся на Star Collector (30 звёзд)
        let target = 30.0
        return Double(storage.totalStarsEarned) / target
    }

    private var nextBadgeLabel: String {
        let remaining = max(0, 30 - storage.totalStarsEarned)
        if remaining == 0 {
            return "You reached Star Collector."
        } else {
            return "\(remaining) stars to Star Collector"
        }
    }
}

