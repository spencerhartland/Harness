//
//  Environment.swift
//  Harness
//
//  Created by Spencer Hartland on 7/23/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var screenSize: CGSize = {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        
        return window.screen.bounds.size
    }()
}
