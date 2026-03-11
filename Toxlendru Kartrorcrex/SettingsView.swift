import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsSection
                resetSection
                linksSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackgroundColor.ignoresSafeArea())
        .navigationTitle("Settings")
        .toolbarBackground(Color.appBackgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Reset All Progress", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                storage.resetAll()
            }
        } message: {
            Text("This will clear stars, levels, badges, and statistics.")
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)

            VStack(spacing: 8) {
                statRow(title: "Total Play Time", value: formatted(time: storage.totalPlayTime))
                statRow(title: "Activities Played", value: "\(storage.totalActivitiesPlayed)")
                statRow(title: "Stars Earned", value: "\(storage.totalStarsEarned)")
                statRow(title: "Levels Completed", value: "\(storage.completedLevelsCount)")
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appSurfaceColor)
            )
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.appTextSecondaryColor)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appTextPrimaryColor)
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)

            Button {
                showResetAlert = true
            } label: {
                Text("Reset All Progress")
                .font(.headline)
                .foregroundColor(.appBackgroundColor)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.appPrimaryColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(ScaledButtonStyle())

            Text("Use this if you want to start fresh from the very beginning.")
                .font(.footnote)
                .foregroundColor(.appTextSecondaryColor)
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(.appTextPrimaryColor)

            Button {
                rateApp()
            } label: {
                HStack {
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Rate this experience")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.appTextPrimaryColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appSurfaceColor)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .buttonStyle(ScaledButtonStyle())

            Button {
                openURL("https://toxlendrukartrorcrex100.site/privacy/32")
            } label: {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Privacy Policy")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.appTextPrimaryColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appSurfaceColor)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .buttonStyle(ScaledButtonStyle())

            Button {
                openURL("https://toxlendrukartrorcrex100.site/terms/32")
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Terms of Use")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.appTextPrimaryColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appSurfaceColor)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .buttonStyle(ScaledButtonStyle())
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

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

