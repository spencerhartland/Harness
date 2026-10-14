//
//  EffectControls.swift
//  Harness
//
//  Created by Spencer Hartland on 10/9/26.
//

import SwiftUI
import SwiftSP621E

struct EffectControls: View {
    @Environment(EffectsStore.self) private var effectsStore
    @Environment(SwiftSP621E.self) private var harness
    
    private static let maxPresetCount: Int = 3
    
    @State private var namingPreset: Bool = false
    @State private var presetName: String = ""
    
    typealias EffectType = SP621EEffect.EffectType
    let effectType: EffectType
    
    init(type: EffectType = .standard) {
        self.effectType = type
    }
    
    var body: some View {
        @Bindable var harness = harness
        
        let presets: [EffectPreset] = effectsStore.allPresets.filter {
            $0.effect.type == effectType
        }
        
        Group {
            if effectType == .audio {
                Section {
                    AudioVisualizerView(for: harness.levels)
                } footer: {
                    Text(
                    """
                    Harness uses audio from your iPhone's microphone to synchronize your harness' \
                    LEDs to music.
                    """
                    )
                }
            }
            
            Section {
                EffectPresetPicker(presets, selected: harness.preset) { preset in
                    harness.preset = preset
                } onDelete: { preset in
                    effectsStore.deletePreset(preset)
                }
            }
            
            let atMaxPresets = presets.count == Self.maxPresetCount
            Section {
                EffectPicker(type: effectType)
                
                Button("Save as Preset") {
                    namingPreset = true
                }
                .buttonStyle(.bordered)
                .buttonSizing(.flexible)
                .controlSize(.large)
                .foregroundStyle(.primary)
                .disabled(atMaxPresets)
                .opacity(atMaxPresets ? 0.5 : 1.0)
                .alert("What should this preset be called?", isPresented: $namingPreset) {
                    let defaultName: String = "Preset \(presets.count + 1)"
                    TextField("Preset Name", text: $presetName, prompt: Text(defaultName))
                    Button("Save Preset", role: .confirm) {
                        let name: String = presetName.isEmpty ? defaultName : presetName
                        savePreset(name)
                    }
                }
            }
        }
        .listSectionSpacing(16)
    }
    
    private func savePreset(_ name: String) {
        let preset = EffectPreset(
            name,
            color: harness.color,
            effect: harness.effect,
            effectSpeed: harness.effectSpeed,
            effectLength: harness.effectLength,
            effectColor: harness.color,
            audioSensitivity: harness.audioSensitivity
        )
        effectsStore.savePreset(preset)
    }
}

#Preview {
    @Previewable @State var effectsStore = EffectsStore()
    @Previewable @State var harness = SwiftSP621E()
    
    NavigationStack {
        List {
            EffectControls(type: .audio)
        }
    }
    .environment(effectsStore)
    .environment(harness)
}
