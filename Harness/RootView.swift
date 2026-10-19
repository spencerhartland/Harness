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
    @AppStorage(UserDefaults.Keys.pairingRequested) private var pairingRequested: Bool = false
    
    @State private var effectsStore = EffectsStore()
    
    var body: some View {
        Group {
            if onboardingRequired {
                NavigationStack {
                    OnboardingView()
                }
            } else {
                NavigationStack {
                    if pairingRequested {
                        PairingView()
                    } else {
                        ControlView()
                    }
                }
                .environment(effectsStore)
            }
        }
        .animation(.default, value: onboardingRequired)
    }
}

#Preview {
    RootView()
}
