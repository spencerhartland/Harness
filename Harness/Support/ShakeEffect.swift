//
//  ShakeEffect.swift
//  Harness
//
//  Created by Spencer Hartland on 8/24/26.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 6
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travel * sin(animatableData * .pi * CGFloat(shakesPerUnit) * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct Shake: ViewModifier {
    private static let travel: CGFloat = 4
    private static let shakesPerUnit = 3

    @State private var shakeAmount: CGFloat = 0
    
    var trigger: Bool

    func body(content: Content) -> some View {
        content
            .modifier(
                ShakeEffect(
                    travel: Self.travel,
                    shakesPerUnit: Self.shakesPerUnit,
                    animatableData: shakeAmount
                )
            )
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.4)) {
                        shakeAmount += 1
                    }
                }
            }
    }
}

extension View {
    func shake(trigger:Bool) -> some View {
        modifier(Shake(trigger: trigger))
    }
}
