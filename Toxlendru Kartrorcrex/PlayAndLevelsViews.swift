import SwiftUI

enum ActivityKind: String, CaseIterable, Identifiable {
    case astroBounce
    case puzzlePath
    case rhythmRun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .astroBounce: return "Astro Bounce"
        case .puzzlePath: return "Puzzle Path"
        case .rhythmRun: return "Rhythm Run"
        }
    }

    var description: String {
        switch self {
        case .astroBounce:
            return "Guide a bouncing star through shifting space obstacles."
        case .puzzlePath:
            return "Rotate tiles to forge a continuous way forward."
        case .rhythmRun:
            return "Tap in rhythm to keep the runner on track."
        }
    }

    var iconName: String {
        switch self {
        case .astroBounce: return "sparkles"
        case .puzzlePath: return "square.grid.3x3.fill"
        case .rhythmRun: return "waveform.path"
        }
    }

    var activityKey: String {
        rawValue
    }

    var levelsCount: Int {
        9
    }
}

struct PlayRootView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var selectedDifficulty: GameDifficulty = .easy

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                difficultySelector

                ForEach(ActivityKind.allCases) { kind in
                    NavigationLink {
                        LevelGridView(activity: kind, difficulty: selectedDifficulty)
                    } label: {
                        ActivityCardView(activity: kind, difficulty: selectedDifficulty)
                    }
                    .buttonStyle(ScaledButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
        .navigationTitle("Play")
        .toolbarBackground(Color.appBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
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
}

struct ActivityCardView: View {
    @EnvironmentObject private var storage: AppStorageManager
    let activity: ActivityKind
    let difficulty: GameDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: activity.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.appAccent)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundColor(.appTextPrimaryColor)
                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(.appTextSecondaryColor)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best stars")
                        .font(.caption2)
                        .foregroundColor(.appTextSecondaryColor)
                    HStack(spacing: 2) {
                        let total = totalStars
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < min(total, 3) ? "star.fill" : "star")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appAccentColor)
                        }
                    }
                }
            }

            ProgressView(value: progress, total: 1.0) {
                EmptyView()
            } currentValueLabel: {
                Text("\(completedLevels)/\(activity.levelsCount) levels")
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary)
            }
            .tint(.appAccentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSurfaceColor)
        )
    }

    private var completedLevels: Int {
        (0..<activity.levelsCount).filter { index in
            let id = LevelIdentifier(activity: activity.activityKey, difficulty: difficulty, index: index)
            return storage.bestStars(for: id) > 0
        }.count
    }

    private var progress: Double {
        guard activity.levelsCount > 0 else { return 0 }
        return Double(completedLevels) / Double(activity.levelsCount)
    }

    private var totalStars: Int {
        (0..<activity.levelsCount).reduce(0) { partial, index in
            let id = LevelIdentifier(activity: activity.activityKey, difficulty: difficulty, index: index)
            return partial + storage.bestStars(for: id)
        }
    }
}

struct LevelGridView: View {
    @EnvironmentObject private var storage: AppStorageManager
    let activity: ActivityKind
    let difficulty: GameDifficulty

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<activity.levelsCount, id: \.self) { index in
                    let identifier = LevelIdentifier(activity: activity.activityKey, difficulty: difficulty, index: index)
                    let unlocked = storage.isLevelUnlocked(activity: activity.activityKey, difficulty: difficulty, index: index)

                    if unlocked {
                        NavigationLink {
                            activityView(for: identifier)
                        } label: {
                            LevelCellView(
                                index: index,
                                bestStars: storage.bestStars(for: identifier),
                                isLocked: false
                            )
                        }
                        .buttonStyle(ScaledButtonStyle())
                    } else {
                        LevelCellView(index: index, bestStars: 0, isLocked: true)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
        .navigationTitle(activity.title)
        .toolbarBackground(Color.appBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private func activityView(for identifier: LevelIdentifier) -> some View {
        switch activity {
        case .astroBounce:
            AstroBounceGameContainer(levelIdentifier: identifier, difficulty: difficulty)
        case .puzzlePath:
            PuzzlePathGameContainer(levelIdentifier: identifier, difficulty: difficulty)
        case .rhythmRun:
            RhythmRunGameContainer(levelIdentifier: identifier, difficulty: difficulty)
        }
    }
}

struct LevelCellView: View {
    let index: Int
    let bestStars: Int
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text("Lv \(index + 1)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.appTextPrimaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appTextSecondaryColor)
                    .frame(height: 22)
            } else {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < bestStars ? "star.fill" : "star")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appAccentColor)
                    }
                }
                .frame(height: 22)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLocked ? Color.appSurfaceColor.opacity(0.6) : Color.appSurfaceColor)
        )
    }
}

