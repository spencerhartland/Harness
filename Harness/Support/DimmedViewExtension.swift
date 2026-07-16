//
//  DimmedViewExtension.swift
//  Harness
//
//  Created by Spencer Hartland on 7/15/26.
//

import SwiftUI

extension View {
    func dimmed(_ dimmed: Bool) -> some View {
        let opacity: Double = dimmed ? 0.6 : 1.0
        
        return self
            .opacity(opacity)
            .listRowBackground(
                Color(uiColor: .secondarySystemGroupedBackground)
                    .opacity(opacity)
            )
    }
}
