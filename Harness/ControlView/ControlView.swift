//
//  ControlView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI
import SwiftSP621E

struct ControlView: View {
    @Environment(SwiftSP621E.self) private var harness
    @Environment(EffectsStore.self) private var effectsStore
    @AppStorage(UserDefaults.Keys.username) private var username: String = ""
    
    private static let maxPresetCount: Int = 3
    
    private var posessiveUsername: String {
        guard let last = username.last else { return username }
        return last == "s" ? "\(username)'" : "\(username)'s"
    }
    
    var body: some View {
        List {
            harnessStatus
                .listRowBackground(Color.clear)
                .listRowInsets(.leading, 0)
            harnessControls
        }
        .onAppear { harness.connect() }
        .navigationTitle(username.isEmpty ? "My Harness" : "\(posessiveUsername) Harness")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Options", systemImage: "ellipsis") {
                    NavigationLink {
                        EditNameView()
                    } label: {
                        Label("Edit Name", systemImage: "pencil")
                    }
                    
                    NavigationLink {
                        ManageDevicesView()
                    } label: {
                        Label("Manage Harness", systemImage: "gearshape.fill")
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var harnessStatus: some View {
        let connectionStatusIcon = harness.connectionState == .disconnected ? "antenna.radiowaves.left.and.right.slash" : "antenna.radiowaves.left.and.right"
        
        StatusItem(
            "Bluetooth",
            statusDescription: harness.connectionState.rawValue,
            systemImage: connectionStatusIcon,
            color: .blue
        )
        .symbolEffect(.variableColor, isActive: harness.connectionState == .connecting)
    }
    
    @ViewBuilder private var harnessControls: some View {
        @Bindable var harness = harness
        
        Section {
            Toggle(isOn: $harness.powerOn.animation()) {
                ControlLabel("Power", systemImage: "power", color: .green)
            }
        }
        .disabled(!harness.isConnected)
        .dimmed(!harness.isConnected)
        
        Group {
            Section("Brightness") {
                Slider(value: $harness.brightness, in: 0...255) {
                    Text("Brightness")
                } minimumValueLabel: {
                    Image(systemName: "sun.min.fill")
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Appearance") {
                Picker("Mode", selection: $harness.mode) {
                    Text(SP621EMode.solidColor.rawValue)
                        .tag(SP621EMode.solidColor)
                    Text(SP621EMode.dynamicEffect.rawValue)
                        .tag(SP621EMode.dynamicEffect)
                }
                .pickerStyle(.segmented)
            }
            
            switch harness.mode {
            case .solidColor:
                colorControls
            case .dynamicEffect:
                effectControls
            case .audio:
                Text("Hello")
            }
        }
//        .disabled(!harness.powerOn)
//        .dimmed(!harness.powerOn)
    }
    
    @ViewBuilder private var colorControls: some View {
        @Bindable var harness = harness
        
        Section {
            ColorPicker(selection: $harness.color, supportsOpacity: false) {
                ControlLabel(
                    "Color",
                    systemImage: "paintpalette.fill",
                    color: .orange
                )
            }
        }
        .listSectionSpacing(16)
    }
    
    @ViewBuilder private var effectControls: some View {
        @Bindable var harness = harness
        
        Group {
            Section { EffectPresetPicker() }
            
            let maxPresets = effectsStore.presets.count == Self.maxPresetCount
            Section {
                EffectPicker(
                    effect: $harness.effect, 
                    speed: $harness.effectSpeed, 
                    length: $harness.effectLength
                )
                
                Button("Save as Preset") {
                    savePreset()
                }
                .buttonStyle(.bordered)
                .buttonSizing(.flexible)
                .controlSize(.large)
                .foregroundStyle(.primary)
                .disabled(maxPresets)
                .opacity(maxPresets ? 0.5 : 1.0)
            }
        }
        .listSectionSpacing(16)
    }
    
    private func savePreset() {
        let presetName = "Preset \(effectsStore.presets.count + 1)"
        let preset = EffectPreset(
            presetName,
            color: .yellow,
            effect: harness.effect,
            effectSpeed: harness.effectSpeed,
            effectLength: harness.effectLength
        )
        effectsStore.savePreset(preset)
    }
    
    private struct StatusItem: View {
        private let title: String
        private let statusDescription: String
        private let systemImage: String
        private let color: Color
        
        init(_ title: String, statusDescription: String, systemImage: String, color: Color) {
            self.title = title
            self.statusDescription = statusDescription
            self.systemImage = systemImage
            self.color = color
        }
        
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .padding(4)
                    .foregroundStyle(color)
                    .imageScale(.medium)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .bold()
                    Text(statusDescription)
                }
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 8)
            .glassEffect()
        }
    }
}

#Preview {
    @Previewable @State var effectsStore = EffectsStore()
    @Previewable @State var harness = SwiftSP621E()
    
    NavigationStack {
        ControlView()
    }
    .environment(harness)
    .environment(effectsStore)
}
