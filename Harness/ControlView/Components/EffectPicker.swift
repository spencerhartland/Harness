//
//  EffectPicker.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI
import SwiftSP621E

struct EffectPicker: View {
    @Environment(EffectsStore.self) private var effectsStore
    
    @Binding var effect: SP621EEffect
    @Binding var effectSpeed: Double
    @Binding var effectLength: Double
    
    init(effect: Binding<SP621EEffect>, speed: Binding<Double>, length: Binding<Double>) {
        self._effect = effect
        self._effectSpeed = speed
        self._effectLength = length
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
                        color: .purple
                    )
                    
                    Spacer()
                    
                    Text(effect.name)
                        .foregroundStyle(.secondary)
                }
            }
            
            effectConfiguration
        }
    }
    
    @ViewBuilder private var effectPicker: some View {
        List {
            let favoriteEffects = [SP621EEffect](effectsStore.favoriteEffects)
            Section {
                if favoriteEffects.isEmpty {
                    VStack {
                        Image(systemName: "star.slash.fill")
                        Text("No favorites")
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                } else {
                    Picker("Favorite Effects", selection: $effect) {
                        ForEach(favoriteEffects) { effect in
                            Text(effect.name).tag(effect)
                        }
                    }
                    .labelsHidden()
                }
            } header: {
                Text("Favorite Effects")
            }
            
            Picker("All Effects", selection: $effect) {
                ForEach(SP621EEffect.allCases) { effect in
                    let isFavorite = effectsStore.favoriteEffects.contains(effect)
                    HStack {
                        Button {
                            if isFavorite {
                                effectsStore.unfavoriteEffect(effect)
                            } else {
                                effectsStore.favoriteEffect(effect)
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
            LabeledSlider("Speed", value: $effectSpeed, in: SP621E.effectSpeedRange)
            LabeledSlider("Length", value: $effectLength, in: SP621E.effectLengthRange)
        }
        .padding([.horizontal, .bottom], 8)
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    @Previewable @State var effectsStore = EffectsStore()
    
    @Previewable @State var previewablePreset = EffectPreset(
        "Preset 1",
        color: .pink,
        effect: .rainbow,
        effectSpeed: 2.0,
        effectLength: 50.0
    )
    
    NavigationStack {
        List {
            EffectPicker(
                effect: $previewablePreset.effect,
                speed: $previewablePreset.effectSpeed,
                length: $previewablePreset.effectLength
            )
        }
    }
    .environment(harness)
    .environment(effectsStore)
}
