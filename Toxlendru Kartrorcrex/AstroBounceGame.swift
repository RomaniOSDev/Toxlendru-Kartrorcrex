import SwiftUI
import Combine

final class AstroBounceViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var starPosition: CGPoint = .zero
    @Published var obstacles: [CGRect] = []
    @Published var progress: Double = 0
    @Published var isCompleted = false
    @Published var didFail = false

    private let difficulty: GameDifficulty
    private var timer: Timer?
    private var lastUpdateDate: Date?
    private var verticalVelocity: CGFloat = 0

    private let levelLength: TimeInterval
    private var elapsed: TimeInterval = 0
    private var playAreaBounds: CGRect = .zero

    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        switch difficulty {
        case .easy:
            levelLength = 18
        case .normal:
            levelLength = 22
        case .hard:
            levelLength = 26
        }
    }

    func start(in rect: CGRect) {
        isRunning = true
        isCompleted = false
        didFail = false
        elapsed = 0
        verticalVelocity = 0
        playAreaBounds = rect
        lastUpdateDate = Date()

        let startY = rect.midY
        starPosition = CGPoint(x: rect.width * 0.2, y: startY)
        generateObstacles(in: rect)

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

    func tapBoost() {
        guard isRunning else { return }
        switch difficulty {
        case .easy:
            verticalVelocity = -260
        case .normal:
            verticalVelocity = -290
        case .hard:
            verticalVelocity = -320
        }
    }

    private func generateObstacles(in rect: CGRect) {
        obstacles.removeAll()
        let count: Int
        switch difficulty {
        case .easy: count = 5
        case .normal: count = 7
        case .hard: count = 9
        }

        for i in 0..<count {
            let spacing = rect.width * 0.6
            let baseX = rect.width * 0.6 + CGFloat(i) * spacing
            let gapHeight: CGFloat
            switch difficulty {
            case .easy: gapHeight = 170
            case .normal: gapHeight = 140
            case .hard: gapHeight = 120
            }

            let gapY = CGFloat.random(in: rect.height * 0.25...(rect.height * 0.75 - gapHeight))
            let obstacleWidth: CGFloat = 40

            let topRect = CGRect(x: baseX, y: 0, width: obstacleWidth, height: gapY)
            let bottomRect = CGRect(x: baseX, y: gapY + gapHeight, width: obstacleWidth, height: rect.height - (gapY + gapHeight))
            obstacles.append(topRect)
            obstacles.append(bottomRect)
        }
    }

    private func tick() {
        guard isRunning, let lastUpdateDate else { return }
        let now = Date()
        let delta = now.timeIntervalSince(lastUpdateDate)
        self.lastUpdateDate = now

        elapsed += delta
        progress = min(1.0, elapsed / levelLength)

        if progress >= 1.0 {
            isCompleted = true
            stop()
            return
        }

        let gravity: CGFloat
        let speed: CGFloat
        switch difficulty {
        case .easy:
            gravity = 420
            speed = 80
        case .normal:
            gravity = 480
            speed = 100
        case .hard:
            gravity = 540
            speed = 120
        }

        verticalVelocity += gravity * CGFloat(delta)
        starPosition.y += verticalVelocity * CGFloat(delta)

        if starPosition.y < 20 || starPosition.y > playAreaBounds.height - 20 {
            didFail = true
            stop()
            return
        }

        obstacles = obstacles.map { rect in
            rect.offsetBy(dx: -speed * CGFloat(delta), dy: 0)
        }.filter { $0.maxX > -10 }

        if obstacles.isEmpty {
            generateObstacles(in: playAreaBounds)
        }

        let starRect = CGRect(x: starPosition.x - 18, y: starPosition.y - 18, width: 36, height: 36)
        for obstacle in obstacles {
            if obstacle.intersects(starRect) {
                didFail = true
                stop()
                return
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}

struct AstroBounceGameContainer: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel: AstroBounceViewModel

    private let levelIdentifier: LevelIdentifier
    private let difficulty: GameDifficulty

    @State private var showResult = false
    @State private var startTime: Date?
    @State private var endTime: Date?
    @State private var finalResult: GameResult?
    @State private var lastPlayArea: CGRect = .zero

    init(levelIdentifier: LevelIdentifier, difficulty: GameDifficulty) {
        self._viewModel = StateObject(wrappedValue: AstroBounceViewModel(difficulty: difficulty))
        self.levelIdentifier = levelIdentifier
        self.difficulty = difficulty
    }

    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 16) {
                    HStack {
                        Text("Astro Bounce")
                            .font(.headline)
                            .foregroundColor(.appTextPrimaryColor)
                        Spacer()
                        ProgressView(value: viewModel.progress)
                            .tint(.appAccentColor)
                            .frame(width: 140)
                    }
                    .padding(.horizontal, 16)

                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.appSurfaceColor)

                        Canvas { context, _ in
                            for obstacle in viewModel.obstacles {
                                let pathRect = CGRect(
                                    x: obstacle.origin.x,
                                    y: obstacle.origin.y,
                                    width: obstacle.width,
                                    height: obstacle.height
                                )
                                var path = Path()
                                path.addRoundedRect(in: pathRect, cornerSize: CGSize(width: 8, height: 8))
                                context.fill(path, with: .color(.appBackgroundColor))
                            }
                        }

                        StarShape(points: 5)
                            .fill(Color.appAccentColor)
                            .frame(width: 32, height: 32)
                            .position(viewModel.starPosition)
                            .shadow(color: .appAccent.opacity(0.9), radius: 10)
                    }
                    .onAppear {
                        startGameIfNeeded(in: geo.frame(in: .local))
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { _ in
                                viewModel.tapBoost()
                            }
                    )

                    Button {
                        viewModel.tapBoost()
                    } label: {
                        Text("Tap to Lift")
                            .font(.headline)
                            .foregroundColor(.appTextPrimaryColor)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.appPrimaryColor))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(ScaledButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed {
                endGame(success: true)
            }
        }
        .onChange(of: viewModel.didFail) { _, failed in
            if failed {
                endGame(success: false)
            }
        }
        .sheet(isPresented: $showResult) {
            if let finalResult {
                ResultScreenView(
                    identifier: levelIdentifier,
                    difficulty: difficulty,
                    result: finalResult,
                    onNextLevel: nextLevelAction,
                    onRetry: retryAction
                )
                .environmentObject(storage)
            } else {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startGameIfNeeded(in rect: CGRect) {
        let playRect = rect.insetBy(dx: 24, dy: 24)
        lastPlayArea = playRect

        guard !viewModel.isRunning else { return }
        startTime = Date()
        endTime = nil
        viewModel.start(in: playRect)
    }

    private func endGame(success: Bool) {
        guard endTime == nil, let startTime else { return }
        endTime = Date()

        let duration = endTime?.timeIntervalSince(startTime) ?? 0
        let stars = starsFor(duration: duration, success: success)
        let accuracy = success ? 1.0 : 0.4

        let levelResult = LevelResult(bestStars: stars, bestTime: duration, bestAccuracy: accuracy)
        storage.setResult(levelResult, for: levelIdentifier)
        storage.addPlaySession(duration: duration)

        let unlocked = computeUnlockedAchievements()
        finalResult = GameResult(
            stars: stars,
            time: duration,
            accuracy: accuracy,
            unlockedAchievementNames: unlocked
        )

        showResult = true
    }

    private func starsFor(duration: TimeInterval, success: Bool) -> Int {
        guard success else { return 1 }
        switch difficulty {
        case .easy:
            if duration < 14 { return 3 }
            if duration < 18 { return 2 }
            return 1
        case .normal:
            if duration < 18 { return 3 }
            if duration < 22 { return 2 }
            return 1
        case .hard:
            if duration < 22 { return 3 }
            if duration < 26 { return 2 }
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

    private func nextLevelAction() {
        endTime = nil
        showResult = false
        restartGameIfPossible()
    }

    private func retryAction() {
        endTime = nil
        showResult = false
        restartGameIfPossible()
    }

    private func restartGameIfPossible() {
        guard lastPlayArea != .zero else { return }
        startTime = Date()
        finalResult = nil
        viewModel.start(in: lastPlayArea)
    }
}

