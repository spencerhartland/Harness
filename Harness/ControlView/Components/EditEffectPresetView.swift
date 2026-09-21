//
//  EditEffectPresetView.swift
//  Harness
//
//  Created by Spencer Hartland on 9/15/26.
//

import SwiftUI
import SwiftSP621E

struct EditEffectPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EffectsStore.self) private var effectsStore
    
    @State private var preset: EffectPreset
    
    init(_ preset: EffectPreset) {
        self.preset = preset
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    ColorPicker("Preset Color", selection: $preset.color)
                        .labelsHidden()
                    TextField("Preset Title", text: $preset.name, prompt: Text("Untitled Preset"))
                }
            }
            
            Section("Effect Settings") {
                EffectPicker(
                    effect: $preset.effect,
                    speed: $preset.effectSpeed,
                    length: $preset.effectLength
                )
            }
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) {
                    effectsStore.savePreset(preset)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    @Previewable @State var effectsStore = EffectsStore()
    
    var previewablePreset = EffectPreset(
        "Preset 1",
        color: .pink,
        effect: .rainbow,
        effectSpeed: 2.0,
        effectLength: 50.0
    )
    
    NavigationStack {
        EditEffectPresetView(previewablePreset)
    }
    .environment(harness)
    .environment(effectsStore)
}
