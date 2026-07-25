//
//  RGB.swift
//  Harness
//
//  Created by Spencer Hartland on 7/13/26.
//

import SwiftUI

public struct RGB: Equatable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    
    public var color: Color {
        get {
            Color(
                red: Double(red) / 255,
                green: Double(green) / 255,
                blue: Double(blue) / 255,
            )
        }
        set {
            let rgb = newValue.rgbBytes
            red = rgb.red
            green = rgb.green
            blue = rgb.blue
        }
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    init(from color: Color) {
        let rgb = color.rgbBytes
        self.red = rgb.red
        self.green = rgb.green
        self.blue = rgb.blue
    }
}
