//
//  RootView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/22/26.
//

import SwiftUI

struct RootView: View {
    @AppStorage(UserDefaults.Keys.onboardingRequired) private var onboardingRequired: Bool = true
    
    @State private var harness = Harness()
    
    var body: some View {
        if onboardingRequired {
            NavigationStack {
                OnboardingView(harness: $harness)
            }
        } else {
            NavigationStack {
                ControlView(harness: $harness)
            }
        }
    }
}

#Preview {
    RootView()
}
