//
//  RootView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/22/26.
//

import SwiftUI
import SwiftSP621E

struct RootView: View {
    @AppStorage(UserDefaults.Keys.onboardingRequired) private var onboardingRequired: Bool = true
    
    @State private var effectsStore = EffectsStore()
    
    var body: some View {
        if onboardingRequired {
            NavigationStack {
                OnboardingView()
            }
        } else {
            NavigationStack {
                ControlView()
            }
            .environment(effectsStore)
        }
    }
}

#Preview {
    RootView()
}
