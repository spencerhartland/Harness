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
    @Environment(SwiftSP621E.self) private var harness
    
    typealias EffectType = SP621EEffect.EffectType
    
    let effectType: EffectType
    
    init(type: EffectType = .standard) {
        self.effectType = type
    }
    
    var body: some View {
        Group {
            NavigationLink {
                effectPicker
            } label: {
                effectPickerLabel
            }
            
            effectConfiguration
        }
    }
    
    private var effectPickerLabel: some View {
        HStack {
            ControlLabel(
                "Effect",
                systemImage: "star.fill",
                color: .purple
            )
            
            Spacer()
            
            Text(harness.effect.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder private var effectPicker: some View {
        @Bindable var harness = harness
        
        List {
            let favoriteEffects: [SP621EEffect] = effectsStore.allFavoriteEffects.filter {
                $0.type == effectType
            }
            
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
                    Picker("Favorite Effects", selection: $harness.effect) {
                        ForEach(favoriteEffects) { effect in
                            Text(effect.name).tag(effect)
                        }
                    }
                    .labelsHidden()
                }
            } header: {
                Text("Favorite Effects")
            }
            
            let allEffects = SP621EEffect.effects.filter { $0.type == effectType }
            
            Picker("All Effects", selection: $harness.effect) {
                ForEach(allEffects) { effect in
                    let isFavorite = favoriteEffects.contains(effect)
                    HStack {
                        Button {
                            if isFavorite {
                                effectsStore.removeFavoriteEffect(effect)
                            } else {
                                effectsStore.addFavoriteEffect(effect)
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
        @Bindable var harness = harness
        
        if effectType == .audio {
            ColorPicker(selection: $harness.color, supportsOpacity: false) {
                ControlLabel(
                    "Color",
                    systemImage: "paintpalette.fill",
                    color: .orange
                )
            }
        }
        
        VStack(alignment: .leading, spacing: 16) {
            switch effectType {
            case .standard:
                LabeledSlider("Speed", value: $harness.effectSpeed, in: SP621E.effectSpeedRange)
            case .audio:
                LabeledSlider(
                    "Sensitivity",
                    value: $harness.audioSensitivity,
                    in: SP621E.audioSensitivityRange
                )
            }
            LabeledSlider("Length", value: $harness.effectLength, in: SP621E.effectLengthRange)
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
        effectLength: 50.0,
        effectColor: .red,
        audioSensitivity: 3.0,
    )
    
    NavigationStack {
        List {
            EffectPicker(type: .audio)
        }
    }
    .environment(harness)
    .environment(effectsStore)
}
