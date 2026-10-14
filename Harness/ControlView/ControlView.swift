//
//  ControlView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI
import Charts
import SwiftSP621E

struct ControlView: View {
    @Environment(SwiftSP621E.self) private var harness
    @Environment(EffectsStore.self) private var effectsStore
    @AppStorage(UserDefaults.Keys.username) private var username: String = ""
    @AppStorage(UserDefaults.Keys.pairingRequested) private var pairingRequested: Bool = false
    
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
                    
                    if !harness.isPaired {
                        Button("Pair Harness", systemImage: "gearshape.fill") {
                            pairingRequested = true
                        }
                    } else {
                        NavigationLink {
                            ManageDevicesView()
                        } label: {
                            Label("Manage Harness", systemImage: "gearshape.fill")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var harnessStatus: some View {
        let connectionStatusIcon = harness.connectionState == .disconnected ? "antenna.radiowaves.left.and.right.slash" : "antenna.radiowaves.left.and.right"
        
        HStack(spacing: 4) {
            Image(systemName: connectionStatusIcon)
                .padding(4)
                .foregroundStyle(.blue)
                .imageScale(.medium)
                .symbolEffect(.variableColor, isActive: harness.connectionState == .connecting)
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 0) {
                Text("Bluetooth")
                    .bold()
                Text(harness.connectionState.rawValue)
            }
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
        .glassEffect()
    }
    
    @ViewBuilder private var harnessControls: some View {
        @Bindable var harness = harness
        
        Section {
            Toggle(isOn: $harness.powerOn.animation()) {
                ControlLabel("Power", systemImage: "power", color: .green)
            }
        }
        .disabled(harness.isPaired && !harness.isConnected)
        .dimmed(harness.isPaired && !harness.isConnected)
        
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
                Picker("Mode", selection: $harness.mode.animation()) {
                    Text(SP621EMode.solidColor.rawValue)
                        .tag(SP621EMode.solidColor)
                    Text(SP621EMode.dynamicEffect.rawValue)
                        .tag(SP621EMode.dynamicEffect)
                    Text(SP621EMode.audioSync.rawValue)
                        .tag(SP621EMode.audioSync)
                }
                .pickerStyle(.segmented)
            }
            
            switch harness.mode {
            case .solidColor:
                colorControls
            case .dynamicEffect:
                EffectControls(type: .standard)
            case .audioSync:
                EffectControls(type: .audio)
            }
        }
        .disabled(harness.isPaired && (!harness.powerOn || !harness.isConnected))
        .dimmed(harness.isPaired && (!harness.powerOn || !harness.isConnected))
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
