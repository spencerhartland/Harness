//
//  AudioEffectPicker.swift
//  Harness
//
//  Created by Spencer Hartland on 9/26/26.
//

import SwiftUI
import SwiftSP621E

struct AudioEffectPicker: View {
    @Environment(EffectsStore.self) private var effectsStore
    
    @Binding var effect: SP621EEffect
    @Binding var color: Color
    @Binding var sensitivity: Double
    @Binding var length: Double
    
    init(
        effect: Binding<SP621EEffect>,
        color: Binding<Color>,
        sensitivity: Binding<Double>,
        length: Binding<Double>
    ) {
        self._effect = effect
        self._color = color
        self._sensitivity = sensitivity
        self._length = length
    }
    
    var body: some View {
        Group {
            NavigationLink {
                effectPicker
            } label: {
                HStack {
                    ControlLabel(
                        "Effect",
                        systemImage: "star.fill",
                        color: .yellow
                    )
                    
                    Spacer()
                    
                    Text(effect.name)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .truncationMode(.tail)
                }
            }
            
            effectConfiguration
        }
    }
    
    @ViewBuilder private var effectPicker: some View {
        List {
            let favorites = [SP621EEffect](effectsStore.favoriteAudioEffects)
            Section {
                if favorites.isEmpty {
                    VStack {
                        Image(systemName: "star.slash.fill")
                        Text("No favorites")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                } else {
                    Picker("Favorite Effects", selection: $effect) {
                        ForEach(favorites) { effect in
                            Text(effect.name).tag(effect)
                        }
                    }
                    .labelsHidden()
                }
            } header: {
                Text("Favorite Effects")
            }
            
            Picker("All Audio Effects", selection: $effect) {
                ForEach(SP621EEffect.audioEffects) { effect in
                    let isFavorite = effectsStore.favoriteAudioEffects.contains(effect)
                    HStack {
                        Button {
                            if isFavorite {
                                effectsStore.unfavoriteAudioEffect(effect)
                            } else {
                                effectsStore.favoriteAudioEffect(effect)
                            }
                        } label: {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .imageScale(.small)
                        }

                        Text(effect.name)
                    }
                    .tag(effect)
                }
            }
        }
        .pickerStyle(.inline)
    }
    
    @ViewBuilder private var effectConfiguration: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledSlider(
                "Sensitivity",
                value: $sensitivity,
                in: SP621E.audioSensitivityRange
            )
            LabeledSlider(
                "Length",
                value: $length,
                in: SP621E.effectLengthRange
            )
        }
        .padding([.horizontal, .bottom], 8)
        
        ColorPicker(selection: $color, supportsOpacity: false) {
            ControlLabel(
                "Color",
                systemImage: "paintpalette.fill",
                color: .orange
            )
        }
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    @Previewable @State var effectsStore = EffectsStore()
    
    @Previewable @State var previewablePreset = EffectPreset(
        "Preset 1",
        color: .pink,
        effect: .fullColorRhythmSpectrum,
        effectSpeed: 2.0,
        effectLength: 50.0,
        audioSensitivity: 3.0
    )
    
    NavigationStack {
        List {
            AudioEffectPicker(
                effect: $previewablePreset.effect,
                color: $previewablePreset.color,
                sensitivity: $previewablePreset.effectSpeed,
                length: $previewablePreset.effectLength
            )
        }
    }
    .environment(harness)
    .environment(effectsStore)
}
