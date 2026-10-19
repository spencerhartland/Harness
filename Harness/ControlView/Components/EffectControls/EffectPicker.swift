//
//  EffectPicker.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI
import SwiftSP621E

struct EffectPicker: View {
    private static let defaultEffectLength: Double = 10
    
    @Environment(EffectsStore.self) private var effectsStore
    @Environment(SwiftSP621E.self) private var harness
    
    @State private var filterColors: Set<SP621EEffect.StandardColor> = []
    @State private var filterEffectPattern: SP621EEffect.Pattern? = nil
    @State private var audioEffectFilter: AudioEffectFilter = .showAll
    
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
            
            let filteredEffects = SP621EEffect.effects.filter {
                guard $0.type == effectType else { return false }
                
                if $0.type == .audio {
                    switch audioEffectFilter {
                    case .showAll:
                        return true
                    case .showMulticolorOnly:
                        guard let palette = $0.palette else { return false }
                        return palette.count > 1
                    case .showSingleColorOnly:
                        guard $0.palette == nil else { return false }
                        return true
                    }
                }
                
                if let filterEffectPattern {
                    guard let pattern = $0.pattern,
                          pattern == filterEffectPattern
                    else {
                        return false
                    }
                }
                
                if !filterColors.isEmpty {
                    guard let palette = $0.palette,
                          palette.contains(filterColors)
                    else {
                        return false
                    }
                }
                
                return true
            }
            
            Picker(selection: $harness.effect) {
                ForEach(filteredEffects) { effect in
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
            } label: {
                HStack {
                    Text("Effects")
                    Spacer()
                    FilterMenu(
                        type: effectType,
                        colors: $filterColors,
                        pattern: $filterEffectPattern,
                        audioEffectFilter: $audioEffectFilter
                    )
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
        
        VStack(alignment: .leading, spacing: 24) {
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
            LabeledSlider(
                "Length",
                value: $harness.effectLength,
                defaultValue: Self.defaultEffectLength,
                in: SP621E.effectLengthRange,
            )
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
