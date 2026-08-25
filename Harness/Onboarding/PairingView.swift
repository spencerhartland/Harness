//
//  PairingView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/23/26.
//

import SwiftUI
import SwiftSP621E

struct PairingView: View {
    @Environment(\.screenSize) private var screenSize
    @AppStorage(UserDefaults.Keys.onboardingRequired) private var onboardingRequired: Bool = true
    
    @Binding var harness: Harness
    
    @State private var selectedDevices: [Device] = []
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                ZStack {
                    progressIndicator
                    completionIndicator
                }
                .padding(.bottom)
                
                if harness.isPaired {
                    connectedInfo
                } else if harness.discoveredDevices.count > 2 {
                    selectionInstructions
                } else {
                    connectionInstructions
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            List(harness.discoveredDevices) { device in
                let selected = selectedDevices.contains(device)
                
                Button {
                    if selected {
                        selectedDevices.removeAll { $0 == device }
                    } else {
                        selectedDevices.append(device)
                    }
                } label: {
                    HStack {
                        Text(device.name)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                            .symbolEffect(.drawOn, isActive: !selected)
                    }
                }
                .foregroundStyle(.primary)
            }
            .scrollContentBackground(.hidden)
            
            Group {
                if harness.isPaired {
                    Button {
                        onboardingRequired = false
                    } label: {
                        Text("Continue")
                    }
                } else {
                    Button {
                        harness.pair(selectedDevices)
                    } label: {
                        Text("Pair")
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.extraLarge)
            .font(.body.bold())
        }
        .padding(32)
        .onAppear {
            harness.connect()
            selectedDevices = [Device](harness.discoveredDevices.prefix(2))
        }
    }
    
    @ViewBuilder private var connectionInstructions: some View {
        Text("Pair your harness")
            .font(.title3.bold())
        Text("Make sure both of the straps are powered on and keep your harness near your iPhone.")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder private var selectionInstructions: some View {
        Text("Pair your harness")
            .font(.title3.bold())
        Text("Multiple harnesses were found. Select your harness' straps from the list below.")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder private var connectedInfo: some View {
        Text("Connected")
            .font(.title3.bold())
        Text("Your harness is now paired.")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    
    private var progressIndicator: some View {
        Image(systemName: "progress.indicator")
            .font(.title3.bold())
            .symbolEffect(
                .variableColor.iterative.hideInactiveLayers.nonReversing,
                options: .repeat(.continuous)
            )
            .symbolEffect(.drawOff.reversed, isActive: harness.isPaired)
    }
    
    private var completionIndicator: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title3.bold())
            .foregroundColor(.green)
            .symbolEffect(.drawOn, isActive: !harness.isPaired)
    }
}

#Preview {
    @Previewable @State var harness = Harness()
    
    NavigationStack {
        PairingView(harness: $harness)
    }
}
