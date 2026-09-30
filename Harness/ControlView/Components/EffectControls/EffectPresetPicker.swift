//
//  EffectPresetPicker.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI
import SwiftSP621E

struct EffectPresetPicker: View {
    @Environment(SwiftSP621E.self) private var harness
    @Environment(EffectsStore.self) private var effectsStore
    
    var body: some View {
        Group {
            if effectsStore.presets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash.fill")
                        .imageScale(.large)
                    Text("No Effect Presets")
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    ForEach(effectsStore.presets) { preset in
                        Menu {
                            Group {
                                NavigationLink {
                                    EditEffectPresetView(preset)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    effectsStore.deletePreset(preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .tint(nil)
                        } label: {
                            VStack {
                                Image(systemName: "star.fill")
                                    .imageScale(.large)
                                    .padding(8)
                                Text(preset.name)
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } primaryAction: {
                            setEffectPreset(preset)
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .buttonStyle(.glassProminent)
                        .tint(preset.color)
                    }
                }
                .listRowBackground(EmptyView())
            }
        }
        .listRowInsets(.vertical, 8)
    }
    
    private func setEffectPreset(_ preset: EffectPreset) {
        harness.effect = preset.effect
        harness.effectSpeed = preset.effectSpeed
        harness.effectLength = preset.effectLength
        harness.powerOn = true
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    @Previewable @State var effectsStore = EffectsStore()
    
    NavigationStack {
        List {
            EffectPresetPicker()
        }
    }
    .environment(harness)
    .environment(effectsStore)
    
}
