import Foundation
import SwiftUI
import Combine

enum GameDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

struct LevelIdentifier: Hashable, Codable {
    let activity: String
    let difficulty: GameDifficulty
    let index: Int

    var storageKey: String {
        "level_\(activity)_\(difficulty.rawValue)_\(index)"
    }
}

struct LevelResult: Codable {
    let bestStars: Int
    let bestTime: TimeInterval
    let bestAccuracy: Double
}

final class AppStorageManager: ObservableObject {
    static let shared = AppStorageManager()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var totalPlayTime: TimeInterval
    @Published private(set) var totalActivitiesPlayed: Int

    @Published private(set) var levelResults: [String: LevelResult]

    private let defaults: UserDefaults

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalPlayTime = "totalPlayTime"
        static let totalActivitiesPlayed = "totalActivitiesPlayed"
        static let levelResults = "levelResults"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults

        self.hasSeenOnboarding = userDefaults.bool(forKey: Keys.hasSeenOnboarding)
        self.totalPlayTime = userDefaults.double(forKey: Keys.totalPlayTime)
        self.totalActivitiesPlayed = userDefaults.integer(forKey: Keys.totalActivitiesPlayed)

        if let data = userDefaults.data(forKey: Keys.levelResults),
           let decoded = try? JSONDecoder().decode([String: LevelResult].self, from: data) {
            self.levelResults = decoded
        } else {
            self.levelResults = [:]
        }
    }

    // MARK: - Onboarding

    func setHasSeenOnboarding() {
        guard hasSeenOnboarding == false else { return }
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        notifyRefresh()
    }

    // MARK: - Level Progress

    func result(for identifier: LevelIdentifier) -> LevelResult? {
        levelResults[identifier.storageKey]
    }

    func bestStars(for identifier: LevelIdentifier) -> Int {
        levelResults[identifier.storageKey]?.bestStars ?? 0
    }

    func setResult(_ newResult: LevelResult, for identifier: LevelIdentifier) {
        let key = identifier.storageKey
        let existing = levelResults[key]

        let shouldReplace: Bool
        if let existing {
            if newResult.bestStars > existing.bestStars {
                shouldReplace = true
            } else if newResult.bestStars == existing.bestStars {
                shouldReplace = newResult.bestTime < existing.bestTime
            } else {
                shouldReplace = false
            }
        } else {
            shouldReplace = true
        }

        guard shouldReplace else { return }

        levelResults[key] = newResult
        persistLevelResults()
        notifyRefresh()
    }

    private func persistLevelResults() {
        if let data = try? JSONEncoder().encode(levelResults) {
            defaults.set(data, forKey: Keys.levelResults)
        }
    }

    // MARK: - Stats

    func addPlaySession(duration: TimeInterval) {
        guard duration > 0 else { return }
        totalPlayTime += duration
        totalActivitiesPlayed += 1
        defaults.set(totalPlayTime, forKey: Keys.totalPlayTime)
        defaults.set(totalActivitiesPlayed, forKey: Keys.totalActivitiesPlayed)
        notifyRefresh()
    }

    // MARK: - Achievements (computed)

    var totalStarsEarned: Int {
        levelResults.values.reduce(0) { $0 + $1.bestStars }
    }

    var completedLevelsCount: Int {
        levelResults.values.filter { $0.bestStars > 0 }.count
    }

    var hasAchievementFirstSteps: Bool {
        completedLevelsCount >= 1
    }

    var hasAchievementStarCollector: Bool {
        totalStarsEarned >= 30
    }

    var hasAchievementFirstPerfect: Bool {
        levelResults.values.contains(where: { $0.bestStars >= 3 })
    }

    var hasAchievementPerfectCollector: Bool {
        let perfectCount = levelResults.values.filter { $0.bestStars >= 3 }.count
        return perfectCount >= 10
    }

    var hasAchievementEasyExplorer: Bool {
        completedLevels(in: .easy) >= 5
    }

    var hasAchievementNormalExplorer: Bool {
        completedLevels(in: .normal) >= 5
    }

    var hasAchievementHardExplorer: Bool {
        completedLevels(in: .hard) >= 3
    }

    var hasAchievementQuestMaster: Bool {
        let activities = ["astroBounce", "puzzlePath", "rhythmRun"]
        let levelCount = 9

        for activity in activities {
            var allCompleted = true
            for index in 0..<levelCount {
                // считается, что уровень "пройден", если на любой сложности есть звезды
                let anyDifficultyCompleted = GameDifficulty.allCases.contains { difficulty in
                    let key = LevelIdentifier(activity: activity, difficulty: difficulty, index: index).storageKey
                    return levelResults[key]?.bestStars ?? 0 > 0
                }
                if !anyDifficultyCompleted {
                    allCompleted = false
                    break
                }
            }
            if allCompleted { return true }
        }
        return false
    }

    var hasAchievementSpeedRunner: Bool {
        // есть любой уровень, завершенный быстрее 15 секунд
        levelResults.values.contains(where: { $0.bestTime > 0 && $0.bestTime <= 15 })
    }

    var hasAchievementAccuracyLover: Bool {
        levelResults.values.contains(where: { $0.bestAccuracy >= 0.95 })
    }

    var hasAchievementMarathon: Bool {
        totalPlayTime >= 30 * 60
    }

    var hasAchievementDedicated: Bool {
        totalActivitiesPlayed >= 50
    }

    private func completedLevels(in difficulty: GameDifficulty) -> Int {
        levelResults.filter { key, value in
            value.bestStars > 0 && key.contains("_\(difficulty.rawValue)_")
        }.count
    }

    // MARK: - Unlock logic

    func isLevelUnlocked(activity: String, difficulty: GameDifficulty, index: Int) -> Bool {
        if index == 0 {
            return true
        }

        let previous = LevelIdentifier(activity: activity, difficulty: difficulty, index: index - 1)
        return bestStars(for: previous) > 0
    }

    // MARK: - Reset

    func resetAll() {
        defaults.removeObject(forKey: Keys.hasSeenOnboarding)
        defaults.removeObject(forKey: Keys.totalPlayTime)
        defaults.removeObject(forKey: Keys.totalActivitiesPlayed)
        defaults.removeObject(forKey: Keys.levelResults)

        hasSeenOnboarding = false
        totalPlayTime = 0
        totalActivitiesPlayed = 0
        levelResults = [:]

        notifyRefresh()
    }

    private func notifyRefresh() {
        NotificationCenter.default.post(name: .appStorageDidResetOrChange, object: nil)
    }
}

extension Notification.Name {
    static let appStorageDidResetOrChange = Notification.Name("appStorageDidResetOrChange")
}

