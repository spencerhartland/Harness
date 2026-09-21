//
//  HarnessApp.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI
import SwiftSP621E

@main
struct HarnessApp: App {
    @State private var harness = SwiftSP621E()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(harness)
        }
    }
}
