//
//  ContentView.swift
//  Toxlendru Kartrorcrex
//
//  Created by Роман Главацкий on 11.03.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var storage: AppStorageManager

    var body: some View {
        ZStack {
            Color.appBackgroundColor
                .ignoresSafeArea()

            if storage.hasSeenOnboarding {
                MainTabShellView()
            } else {
                OnboardingFlowView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStorageManager.shared)
}
