//
//  ControlView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI
import SwiftSP621E

struct ControlView: View {
    @AppStorage(UserDefaults.Keys.username) private var username: String = ""
    
    @Binding var harness: Harness
    
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
                .disabled(!harness.isConnected)
                .dimmed(!harness.isConnected)
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
                        ManageDevicesView(harness: $harness)
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
        Section {
            Toggle(isOn: $harness.isOn.animation()) {
                ControlLabel("Power", systemImage: "power", color: .green)
            }
        }
        
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
            
            Section {
                switch harness.mode {
                case .solidColor:
                    colorControls
                case .dynamicEffect:
                    effectControls
                }
            }
            .listSectionSpacing(16)
        }
        .disabled(!harness.isOn)
        .dimmed(!harness.isOn)
    }
    
    private var colorControls: some View {
        ColorPicker(selection: $harness.color, supportsOpacity: false) {
            ControlLabel(
                "Color",
                systemImage: "paintpalette.fill",
                color: .orange
            )
        }
    }
    
    @ViewBuilder private var effectControls: some View {
        Picker(selection: $harness.effect) {
            Text("Rainbow").tag(SP621EEffect.rainbow)
        } label: {
            ControlLabel(
                "Effect",
                systemImage: "sparkles",
                color: .purple
            )
        }
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in
            dimensions[.leading]
        }
        
        Slider(value: $harness.effectSpeed, in: 1...10) {
            Text("Effect Speed")
        } minimumValueLabel: {
            SliderValueLabel(systemImage: "tortoise.fill")
        } maximumValueLabel: {
            SliderValueLabel(systemImage: "hare.fill")
        }
        
        Slider(value: $harness.effectLength, in: 1...150) {
            Text("Effect Length")
        } minimumValueLabel: {
            SliderValueLabel(systemImage: "minus.circle.fill")
        } maximumValueLabel: {
            SliderValueLabel(systemImage: "plus.circle.fill")
        }
    }
    
    private struct SliderValueLabel: View {
        let systemImage: String
        let size: CGFloat
        
        init(systemImage: String, size: CGFloat = 24) {
            self.systemImage = systemImage
            self.size = size
        }
        
        var body: some View {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
        }
    }
    
    private struct ControlLabel: View {
        private let title: String
        private let systemImage: String
        private let color: Color
        
        init(_ title: String, systemImage: String, color: Color) {
            self.title = title
            self.systemImage = systemImage
            self.color = color
        }
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .padding(4)
                    .background {
                        color
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .aspectRatio(1.0, contentMode: .fill)
                    }
                    .foregroundStyle(Color.white)
                    .bold()
                Text(title)
            }
        }
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
    @Previewable @State var harness = Harness()
    
    NavigationStack {
        ControlView(harness: $harness)
    }
}
