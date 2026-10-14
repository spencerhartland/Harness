//
//  EffectPresetPicker.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI
import SwiftSP621E

struct EffectPresetPicker: View {
    let presets: [EffectPreset]
    let selectedPreset: EffectPreset?
    let onSelect: (EffectPreset) -> Void
    let onDelete: (EffectPreset) -> Void
    
    init(
        _ presets: [EffectPreset],
        selected: EffectPreset? = nil,
        onSelect: @escaping (EffectPreset) -> Void,
        onDelete: @escaping (EffectPreset) -> Void,
    ) {
        self.presets = presets
        self.selectedPreset = selected
        self.onSelect = onSelect
        self.onDelete = onDelete
    }
    
    var body: some View {
        Group {
            if presets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash.fill")
                        .imageScale(.large)
                    Text("No Presets")
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    ForEach(presets) { preset in
                        VStack {
                            Menu {
                                Group {
                                    NavigationLink {
                                        EditEffectPresetView(preset)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        onDelete(preset)
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
                                withAnimation { onSelect(preset) }
                            }
                            .buttonBorderShape(.roundedRectangle)
                            .buttonStyle(.glassProminent)
                            .tint(preset.color)
                            
                            activePresetIndicator
                                .opacity(preset == selectedPreset ? 1 : 0)
                        }
                    }
                }
                .listRowBackground(EmptyView())
            }
        }
        .listRowInsets(.vertical, 8)
    }
    
    private var activePresetIndicator: some View {
        Circle()
            .foregroundStyle(.secondary)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 6)
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    @Previewable @State var effectsStore = EffectsStore()
    
    NavigationStack {
        List {
            EffectPresetPicker(effectsStore.standardPresets, selected: harness.preset) { preset in
                harness.preset = preset
            } onDelete: { preset in
                effectsStore.deletePreset(preset)
            }
        }
    }
    .environment(harness)
    .environment(effectsStore)
    
}
