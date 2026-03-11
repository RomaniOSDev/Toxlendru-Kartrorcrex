import SwiftUI
import Combine

final class RhythmRunViewModel: ObservableObject {
    @Published var currentTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval
    @Published var beats: [TimeInterval] = []
    @Published var hitWindows: [Bool] = []
    @Published var isRunning = false
    @Published var isCompleted = false
    @Published var didFail = false

    private let difficulty: GameDifficulty
    private var timer: Timer?
    private var startDate: Date?
    private var hitCount: Int = 0
    private var missCount: Int = 0

    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty

        switch difficulty {
        case .easy:
            totalDuration = 16
        case .normal:
            totalDuration = 18
        case .hard:
            totalDuration = 20
        }

        generatePattern()
    }

    func restart() {
        stop()
        currentTime = 0
        hitCount = 0
        missCount = 0
        generatePattern()
        start()
    }

    private func generatePattern() {
        beats.removeAll()
        let interval: TimeInterval
        switch difficulty {
        case .easy:
            interval = 1.0
        case .normal:
            interval = 0.8
        case .hard:
            interval = 0.6
        }

        var t: TimeInterval = 2.0
        while t < totalDuration - 1.0 {
            beats.append(t)
            if difficulty == .hard && Bool.random() {
                beats.append(t + interval / 2.0)
            }
            t += interval
        }
        beats.sort()
        hitWindows = Array(repeating: false, count: beats.count)
    }

    func start() {
        isRunning = true
        isCompleted = false
        didFail = false
        hitCount = 0
        missCount = 0
        currentTime = 0
        startDate = Date()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning, let startDate else { return }
        currentTime = Date().timeIntervalSince(startDate)

        if currentTime >= totalDuration {
            finalize()
        }
    }

    private func finalize() {
        isRunning = false
        stop()

        let accuracy = accuracyScore
        if accuracy >= 0.4 {
            isCompleted = true
        } else {
            didFail = true
        }
    }

    func registerTap() {
        guard isRunning else { return }

        let window: TimeInterval
        switch difficulty {
        case .easy:
            window = 0.28
        case .normal:
            window = 0.18
        case .hard:
            window = 0.12
        }

        if let index = beats.indices.min(by: { lhs, rhs in
            abs(beats[lhs] - currentTime) < abs(beats[rhs] - currentTime)
        }) {
            let distance = abs(beats[index] - currentTime)
            if distance <= window {
                if !hitWindows[index] {
                    hitWindows[index] = true
                    hitCount += 1
                }
            } else {
                missCount += 1
            }
        } else {
            missCount += 1
        }

        if currentTime >= totalDuration - 0.1 {
            finalize()
        }
    }

    var accuracyScore: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0 }
        return Double(hitCount) / Double(total)
    }

    deinit {
        timer?.invalidate()
    }
}

struct RhythmRunGameContainer: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel: RhythmRunViewModel

    private let levelIdentifier: LevelIdentifier
    private let difficulty: GameDifficulty

    @State private var showResult = false
    @State private var startTime: Date?
    @State private var endTime: Date?
    @State private var finalResult: GameResult?

    init(levelIdentifier: LevelIdentifier, difficulty: GameDifficulty) {
        _viewModel = StateObject(wrappedValue: RhythmRunViewModel(difficulty: difficulty))
        self.levelIdentifier = levelIdentifier
        self.difficulty = difficulty
    }

    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()

            VStack(spacing: 20) {
                header
                trackView
                tapButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            startTime = Date()
            viewModel.start()
        }
        .onChange(of: viewModel.isCompleted) { _, done in
            if done {
                endLevel()
            }
        }
        .onChange(of: viewModel.didFail) { _, failed in
            if failed {
                endLevel()
            }
        }
        .sheet(isPresented: $showResult) {
            if let finalResult {
                ResultScreenView(
                    identifier: levelIdentifier,
                    difficulty: difficulty,
                    result: finalResult,
                    onNextLevel: restartSession,
                    onRetry: restartSession
                )
                .environmentObject(storage)
            } else {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            Text("Rhythm Run")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
            Spacer()
            Text("\(Int(viewModel.currentTime))s")
                .font(.subheadline)
                .foregroundColor(.appTextSecondaryColor)
        }
        .padding(.top, 8)
    }

    private var trackView: some View {
        GeometryReader { geo in
            let width = geo.size.width - 32
            let height: CGFloat = 140

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appSurfaceColor)

                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let trackY = rect.midY

                    var base = Path()
                    base.move(to: CGPoint(x: 16, y: trackY))
                    base.addLine(to: CGPoint(x: rect.width - 16, y: trackY))
                    context.stroke(base, with: .color(.appTextSecondaryColor.opacity(0.5)), lineWidth: 3)

                    for (index, beat) in viewModel.beats.enumerated() {
                        let progress = CGFloat(beat / max(viewModel.totalDuration, 0.1))
                        let x = 16 + (rect.width - 32) * progress
                        let isHit = viewModel.hitWindows.indices.contains(index) ? viewModel.hitWindows[index] : false

                        let radius: CGFloat = isHit ? 8 : 6
                        let color: Color = isHit ? .appAccentColor : .appPrimaryColor

                        let circleRect = CGRect(x: x - radius, y: trackY - radius, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: circleRect), with: .color(color))
                    }

                    let runnerProgress = CGFloat(viewModel.currentTime / max(viewModel.totalDuration, 0.1))
                    let runnerX = 16 + (rect.width - 32) * runnerProgress
                    let runnerRect = CGRect(x: runnerX - 10, y: trackY - 22, width: 20, height: 44)
                    let runnerPath = Path(roundedRect: runnerRect, cornerRadius: 10)
                    context.fill(runnerPath, with: .color(.appAccentColor))
                }
            }
            .frame(width: width, height: height)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: 180)
    }

    private var tapButton: some View {
        Button {
            viewModel.registerTap()
        } label: {
            Text("Tap in Rhythm")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.appPrimaryColor))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(ScaledButtonStyle())
    }

    private func endLevel() {
        guard endTime == nil, let startTime else { return }
        endTime = Date()

        let duration = endTime?.timeIntervalSince(startTime) ?? 0
        let accuracy = max(0.05, viewModel.accuracyScore)
        let stars = starsFor(accuracy: accuracy)

        let levelResult = LevelResult(bestStars: stars, bestTime: duration, bestAccuracy: accuracy)
        storage.setResult(levelResult, for: levelIdentifier)
        storage.addPlaySession(duration: duration)

        finalResult = GameResult(
            stars: stars,
            time: duration,
            accuracy: accuracy,
            unlockedAchievementNames: computeUnlockedAchievements()
        )

        showResult = true
    }

    private func restartSession() {
        showResult = false
        endTime = nil
        startTime = Date()
        finalResult = nil
        viewModel.restart()
    }

    private func starsFor(accuracy: Double) -> Int {
        switch difficulty {
        case .easy:
            if accuracy >= 0.85 { return 3 }
            if accuracy >= 0.6 { return 2 }
            return 1
        case .normal:
            if accuracy >= 0.8 { return 3 }
            if accuracy >= 0.55 { return 2 }
            return 1
        case .hard:
            if accuracy >= 0.75 { return 3 }
            if accuracy >= 0.5 { return 2 }
            return 1
        }
    }

    private func computeUnlockedAchievements() -> [String] {
        var names: [String] = []
        if storage.hasAchievementFirstSteps {
            names.append("First Steps")
        }
        if storage.hasAchievementStarCollector {
            names.append("Star Collector")
        }
        if storage.hasAchievementMarathon {
            names.append("Marathon Mode")
        }
        if storage.hasAchievementDedicated {
            names.append("Dedicated Player")
        }
        return names
    }
}

