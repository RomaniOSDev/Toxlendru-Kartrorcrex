import SwiftUI
import Combine

struct PuzzleTile: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    var rotation: Int
    var isHiddenInitially: Bool
    var hasStart: Bool
    var hasEnd: Bool

    // Connections in base (0°) orientation: up/right/down/left
    var baseConnections: [Bool]

    mutating func rotate() {
        rotation = (rotation + 1) % 4
    }

    var currentConnections: [Bool] {
        let count = baseConnections.count
        let shift = rotation % count
        return Array(baseConnections[shift...] + baseConnections[..<shift])
    }
}

final class PuzzlePathViewModel: ObservableObject {
    @Published var tiles: [PuzzleTile] = []
    @Published var isCompleted = false
    @Published var didFail = false

    private let rows: Int
    private let cols: Int
    private let difficulty: GameDifficulty
    private var revealThreshold: Int = 0
    private var totalRotations: Int = 0

    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        switch difficulty {
        case .easy:
            rows = 3
            cols = 3
        case .normal:
            rows = 4
            cols = 4
        case .hard:
            rows = 4
            cols = 5
        }
        setupLevel()
    }

    func reset() {
        setupLevel()
    }

    private func setupLevel() {
        tiles.removeAll()
        isCompleted = false
        didFail = false
        totalRotations = 0

        revealThreshold = difficulty == .hard ? 6 : 0

        for row in 0..<rows {
            for col in 0..<cols {
                let isStart = (row == rows / 2 && col == 0)
                let isEnd = (row == rows / 2 && col == cols - 1)

                let base: [Bool]
                if isStart {
                    base = [false, true, false, false]
                } else if isEnd {
                    base = [false, false, false, true]
                } else if col < cols - 1 && row == rows / 2 {
                    base = [false, true, false, true]
                } else {
                    let r = (row + col) % 3
                    switch r {
                    case 0:
                        base = [false, true, true, false]
                    case 1:
                        base = [true, false, false, true]
                    default:
                        base = [true, true, false, false]
                    }
                }

                let hidden = difficulty == .hard && !isStart && !isEnd && Bool.random()
                let tile = PuzzleTile(
                    row: row,
                    col: col,
                    rotation: Int.random(in: 0..<4),
                    isHiddenInitially: hidden,
                    hasStart: isStart,
                    hasEnd: isEnd,
                    baseConnections: base
                )
                tiles.append(tile)
            }
        }
    }

    func tile(atRow row: Int, col: Int) -> PuzzleTile? {
        tiles.first(where: { $0.row == row && $0.col == col })
    }

    func rotate(tile: PuzzleTile) {
        guard let index = tiles.firstIndex(where: { $0.id == tile.id }), !isCompleted else { return }
        tiles[index].rotate()
        if tiles[index].isHiddenInitially && revealThreshold > 0 {
            totalRotations += 1
            if totalRotations >= revealThreshold {
                for idx in tiles.indices where tiles[idx].isHiddenInitially {
                    tiles[idx].isHiddenInitially = false
                }
            }
        }
        checkCompletion()
    }

    private func checkCompletion() {
        guard let startTile = tiles.first(where: { $0.hasStart }) else { return }

        var visited: Set<String> = []
        var queue: [(Int, Int)] = [(startTile.row, startTile.col)]
        var reachedEnd = false

        func key(_ r: Int, _ c: Int) -> String { "\(r)-\(c)" }

        while !queue.isEmpty {
            let (row, col) = queue.removeFirst()
            let k = key(row, col)
            if visited.contains(k) { continue }
            visited.insert(k)

            guard let currentTile = tile(atRow: row, col: col) else { continue }

            if currentTile.hasEnd {
                reachedEnd = true
                break
            }

            let conn = currentTile.currentConnections
            if conn[0], row > 0,
               let neighbor = self.tile(atRow: row - 1, col: col),
               neighbor.currentConnections[2] {
                queue.append((row - 1, col))
            }
            if conn[1], col < cols - 1,
               let neighbor = self.tile(atRow: row, col: col + 1),
               neighbor.currentConnections[3] {
                queue.append((row, col + 1))
            }
            if conn[2], row < rows - 1,
               let neighbor = self.tile(atRow: row + 1, col: col),
               neighbor.currentConnections[0] {
                queue.append((row + 1, col))
            }
            if conn[3], col > 0,
               let neighbor = self.tile(atRow: row, col: col - 1),
               neighbor.currentConnections[1] {
                queue.append((row, col - 1))
            }
        }

        isCompleted = reachedEnd
    }
}

struct PuzzlePathGameContainer: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel: PuzzlePathViewModel

    private let levelIdentifier: LevelIdentifier
    private let difficulty: GameDifficulty

    @State private var showResult = false
    @State private var startTime: Date?
    @State private var endTime: Date?
    @State private var finalResult: GameResult?

    init(levelIdentifier: LevelIdentifier, difficulty: GameDifficulty) {
        _viewModel = StateObject(wrappedValue: PuzzlePathViewModel(difficulty: difficulty))
        self.levelIdentifier = levelIdentifier
        self.difficulty = difficulty
    }

    var body: some View {
        ZStack {
            Color.appBackgroundColor.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                puzzleGrid

                Text("Tap tiles to rotate and build a continuous route from start to finish.")
                    .font(.footnote)
                    .foregroundColor(.appTextSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            startTime = Date()
        }
        .onChange(of: viewModel.isCompleted) { _, done in
            if done {
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
            Text("Puzzle Path")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var puzzleGrid: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 32, geo.size.height - 32)
            let tileSize = side / CGFloat(max(viewModelTilesRows, viewModelTilesCols))

            VStack {
                ForEach(0..<viewModelTilesRows, id: \.self) { row in
                    HStack {
                        ForEach(0..<viewModelTilesCols, id: \.self) { col in
                            if let tile = viewModel.tile(atRow: row, col: col) {
                                PuzzleTileView(tile: tile, size: tileSize)
                                    .onTapGesture {
                                        viewModel.rotate(tile: tile)
                                    }
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appSurfaceColor)
            )
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .padding(.horizontal, 16)
        .frame(height: 320)
    }

    private var viewModelTilesRows: Int {
        viewModel.tiles.map { $0.row }.max().map { $0 + 1 } ?? 0
    }

    private var viewModelTilesCols: Int {
        viewModel.tiles.map { $0.col }.max().map { $0 + 1 } ?? 0
    }

    private func endLevel() {
        guard endTime == nil, let startTime else { return }
        endTime = Date()
        let duration = endTime?.timeIntervalSince(startTime) ?? 0

        let stars = starsFor(duration: duration)
        let accuracy: Double
        switch difficulty {
        case .easy: accuracy = 0.9
        case .normal: accuracy = 0.85
        case .hard: accuracy = 0.8
        }

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
        viewModel.reset()
    }

    private func starsFor(duration: TimeInterval) -> Int {
        switch difficulty {
        case .easy:
            if duration < 20 { return 3 }
            if duration < 40 { return 2 }
            return 1
        case .normal:
            if duration < 40 { return 3 }
            if duration < 70 { return 2 }
            return 1
        case .hard:
            if duration < 70 { return 3 }
            if duration < 110 { return 2 }
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

struct PuzzleTileView: View {
    let tile: PuzzleTile
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(tile.isHiddenInitially ? Color.appSurfaceColor.opacity(0.5) : Color.appSurfaceColor)

            if !tile.isHiddenInitially {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let lineWidth: CGFloat = 6

                    func drawSegment(from: CGPoint, to: CGPoint) {
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.appAccent), lineWidth: lineWidth)
                    }

                    let radius = min(size.width, size.height) / 2 - 10
                    let upPoint = CGPoint(x: center.x, y: center.y - radius)
                    let rightPoint = CGPoint(x: center.x + radius, y: center.y)
                    let downPoint = CGPoint(x: center.x, y: center.y + radius)
                    let leftPoint = CGPoint(x: center.x - radius, y: center.y)

                    let connections = tile.currentConnections

                    if connections[0] {
                        drawSegment(from: center, to: upPoint)
                    }
                    if connections[1] {
                        drawSegment(from: center, to: rightPoint)
                    }
                    if connections[2] {
                        drawSegment(from: center, to: downPoint)
                    }
                    if connections[3] {
                        drawSegment(from: center, to: leftPoint)
                    }

                    if tile.hasStart || tile.hasEnd {
                        let color: Color = tile.hasStart ? .appPrimaryColor : .appAccentColor
                        let circleRect = CGRect(
                            x: center.x - 8,
                            y: center.y - 8,
                            width: 16,
                            height: 16
                        )
                        context.fill(Path(ellipseIn: circleRect), with: .color(color))
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

