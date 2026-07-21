//
//  RootView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI

struct RootView: View {
    private static let title: String = "Pup Aphex's Harness"
    
    @State private var harness = Harness()
    
    @State private var isConnected: Bool = false
    
    var body: some View {
        List {
            harnessStatus
                .listRowBackground(Color.clear)
            harnessControls
        }
        .onAppear { harness.connect() }
    }
    
    private var harnessStatus: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Self.title)
                .font(.largeTitle.bold())
            HStack {
                let connectionStatusDescription = harness.state == .connected ? "Connected" : "Disconnected"
                let connectionStatusIcon = harness.state == .connected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
                
                StatusItem(
                    "Bluetooth",
                    statusDescription: connectionStatusDescription,
                    systemImage: connectionStatusIcon,
                    color: .blue
                )
                StatusItem(
                    "Battery",
                    statusDescription: "100%",
                    systemImage: "battery.100percent",
                    color: .primary
                )
            }
        }
    }
    
    @ViewBuilder private var harnessControls: some View {
        Section {
            Toggle(isOn: $harness.isPoweredOn.animation()) {
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
                    Text(SP621E.Mode.solidColor.rawValue)
                        .tag(SP621E.Mode.solidColor)
                    Text(SP621E.Mode.dynamicEffect.rawValue)
                        .tag(SP621E.Mode.dynamicEffect)
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
        .disabled(!harness.isPoweredOn)
        .dimmed(!harness.isPoweredOn)
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
            Text("Rainbow").tag(SP621E.Effect.rainbow)
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
            .background {
                Capsule()
                    .fill(Color(uiColor: .systemFill))
            }
        }
    }
}

#Preview {
    RootView()
}
