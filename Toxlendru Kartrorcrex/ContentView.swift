//
//  ContentView.swift
//  Toxlendru Kartrorcrex
//
//  Created by Роман Главацкий on 11.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var storage = AppStorageManager.shared

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
        .environmentObject(storage)
    }
}

#Preview {
    ContentView()
}
