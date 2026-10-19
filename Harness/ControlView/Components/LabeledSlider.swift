//
//  LabeledSlider.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI

struct LabeledSlider<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
    @Binding var value: V
    
    let title: LocalizedStringKey
    let defaultValue: V?
    let bounds: ClosedRange<V>
    
    init(
        _ titleKey: LocalizedStringKey,
        value: Binding<V>,
        defaultValue: V? = nil,
        in bounds: ClosedRange<V>,
    ) {
        self.title = titleKey
        self._value = value
        self.defaultValue = defaultValue
        self.bounds = bounds
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                
                if let defaultValue { returnToDefaultButton(defaultValue) }
            }

            Slider(value: $value, in: bounds)
                .onAppear {
                    if let defaultValue { value = defaultValue }
                }
        }
    }
    
    private func returnToDefaultButton(_ defaultValue: V) -> some View {
        Button {
            withAnimation { value = defaultValue }
        }label: {
            Label("Default", systemImage: "arrow.uturn.backward")
                .labelIconToTitleSpacing(4)
        }
        .buttonStyle(.glass)
        .controlSize(.small)
        .foregroundStyle(.secondary)
        .disabled(value == defaultValue)
    }
}

#Preview {
    @Previewable @State var sliderValue: Double = 0.0
    
    LabeledSlider("Test", value: $sliderValue, defaultValue: 10, in: 1...150)
}
