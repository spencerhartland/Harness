//
//  LabeledSlider.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI

struct LabeledSlider<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
    
    let title: LocalizedStringKey
    let value: Binding<V>
    let bounds: ClosedRange<V>
    
    init(
        _ titleKey: LocalizedStringKey,
        value: Binding<V>,
        in bounds: ClosedRange<V>,
    ) {
        self.title = titleKey
        self.value = value
        self.bounds = bounds
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(.secondary)
            Slider(value: value, in: bounds)
        }
    }
}
