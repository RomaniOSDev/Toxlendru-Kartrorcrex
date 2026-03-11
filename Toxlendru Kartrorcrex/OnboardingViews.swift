import SwiftUI

private struct OnboardingPageData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let accent: Color
}

struct OnboardingFlowView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var currentIndex: Int = 0

    private let pages: [OnboardingPageData] = [
        .init(title: "Quick Missions",
              description: "Short and dynamic challenges that fit any moment.",
              accent: .appPrimaryColor),
        .init(title: "Skillful Play",
              description: "Test your reflexes, logic, and rhythm in focused runs.",
              accent: .appAccentColor),
        .init(title: "Collect Stars",
              description: "Earn stars, unlock levels, and chase new badges.",
              accent: .appPrimaryColor)
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentIndex)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.appPrimaryColor : Color.appSurfaceColor)
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                    }
                }

                Button(action: advance) {
                    Text(currentIndex == pages.count - 1 ? "Start Playing" : "Next")
                        .font(.headline)
                        .foregroundColor(.appTextPrimaryColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.appPrimary.cornerRadius(16))
                }
                .buttonStyle(ScaledButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .background(Color.appBackgroundColor.opacity(0.95))
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
    }

    private func advance() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
        } else {
            storage.setHasSeenOnboarding()
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPageData
    @State private var animateShape: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let center = CGPoint(x: rect.midX, y: rect.midY)

                    switch page.title {
                    case "Quick Missions":
                        // Орбита с вращающейся звездой
                        var orbit = Path()
                        orbit.addEllipse(in: rect.insetBy(dx: 20, dy: 20))
                        context.stroke(orbit, with: .color(page.accent.opacity(0.4)), lineWidth: 2)

                        let progress = animateShape ? 1.0 : 0.0
                        let angle = Angle.degrees(progress * 360)
                        let radius = min(rect.width, rect.height) / 2 - 24
                        let point = CGPoint(
                            x: center.x + CGFloat(cos(angle.radians)) * radius,
                            y: center.y + CGFloat(sin(angle.radians)) * radius
                        )

                        let star = StarShape(points: 5).path(in: CGRect(x: point.x - 16, y: point.y - 16, width: 32, height: 32))
                        context.fill(star, with: .color(page.accent))
                        context.addFilter(.shadow(color: page.accent.opacity(0.7), radius: 12, x: 0, y: 0))
                        context.stroke(star, with: .color(.appSurfaceColor), lineWidth: 1)

                    case "Skillful Play":
                        // Ломанные дорожки с бегущим маркером
                        var path = Path()
                        let width = rect.width - 40
                        let height = rect.height - 80
                        let start = CGPoint(x: center.x - width / 2, y: center.y + height / 2)
                        path.move(to: start)
                        path.addLine(to: CGPoint(x: start.x + width * 0.35, y: start.y - height * 0.6))
                        path.addLine(to: CGPoint(x: start.x + width * 0.7, y: start.y - height * 0.1))
                        path.addLine(to: CGPoint(x: start.x + width, y: start.y - height * 0.8))

                        context.stroke(path, with: .color(page.accent.opacity(0.7)), lineWidth: 4)

                        let progress = animateShape ? 1.0 : 0.0
                        let clamped = max(0.0, min(1.0, progress))
                        let markerX = start.x + width * CGFloat(clamped)
                        let tY = start.y - height * CGFloat(0.2 + 0.6 * sin(clamped * .pi))
                        let markerRect = CGRect(x: markerX - 10, y: tY - 10, width: 20, height: 20)
                        context.fill(Path(ellipseIn: markerRect), with: .color(page.accent))

                    case "Collect Stars":
                        // Кучка звёзд с пульсацией
                        let baseRadius: CGFloat = min(rect.width, rect.height) / 4
                        let progress = animateShape ? 1.0 : 0.0
                        let scale = 0.9 + 0.1 * sin(progress * .pi * 2)

                        for i in 0..<5 {
                            let angle = Double(i) / 5.0 * Double.pi * 2
                            let r = baseRadius * 0.7
                            let point = CGPoint(
                                x: center.x + CGFloat(cos(angle)) * r,
                                y: center.y + CGFloat(sin(angle)) * r
                            )
                            let starRect = CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)
                            let star = StarShape(points: 5).path(in: starRect)
                            context.fill(star, with: .color(page.accent))
                        }

                        let mainRect = CGRect(
                            x: center.x - 18 * CGFloat(scale),
                            y: center.y - 18 * CGFloat(scale),
                            width: 36 * CGFloat(scale),
                            height: 36 * CGFloat(scale)
                        )
                        let mainStar = StarShape(points: 5).path(in: mainRect)
                        context.fill(mainStar, with: .color(page.accent))
                        context.addFilter(.shadow(color: page.accent.opacity(0.8), radius: 14, x: 0, y: 0))

                    default:
                        break
                    }
                }
                .frame(height: 260)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.appSurface)
                )
                .padding(.top, 24)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        animateShape = true
                    }
                }

                VStack(spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimaryColor)
                        .multilineTextAlignment(.center)

                    Text(page.description)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondaryColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

