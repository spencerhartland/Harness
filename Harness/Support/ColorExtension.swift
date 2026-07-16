//
//  ColorExtension.swift
//  Harness
//
//  Created by Spencer Hartland on 7/13/26.
//

import SwiftUI

extension Color {
    var rgbBytes: (red: UInt8, green: UInt8, blue: UInt8) {
        let resolved = resolve(in: EnvironmentValues())
        return (
            channelByte(resolved.red),
            channelByte(resolved.green),
            channelByte(resolved.blue)
        )
    }

    private func channelByte(_ component: Float) -> UInt8 {
        let clamped = min(max(component, 0), 1)
        return UInt8((clamped * 255).rounded())
    }
}
