//
//  PairingView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/23/26.
//

import SwiftUI
import SwiftSP621E

struct PairingView: View {
    @Environment(SwiftSP621E.self) private var harness
    @Environment(\.screenSize) private var screenSize
    @AppStorage(UserDefaults.Keys.onboardingRequired) private var onboardingRequired: Bool = true
    
    @State private var selectedControllers: [DiscoveredSP621E] = []
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    ZStack {
                        progressIndicator
                        completionIndicator
                    }
                    .padding(.bottom)
                    
                    if harness.isPaired {
                        connectedInfo
                    } else if harness.discoveredControllers.count > 2 {
                        selectionInstructions
                    } else {
                        connectionInstructions
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            
            Section {
                ForEach(selectedControllers) { device in
                    Button(device.name) {
                        selectedControllers.removeAll { $0 == device }
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                HStack {
                    Text("Selected Controllers")
                    Spacer()
                    Text("\(selectedControllers.count)/2")
                }
            }
            
            Section("Discovered Controllers") {
                let discoveredControllers = harness.discoveredControllers.filter {
                    !selectedControllers.contains($0)
                }
                
                ForEach(discoveredControllers) { controller in
                    Button(controller.name) {
                        selectedControllers.append(controller)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if harness.isPaired {
                    Button {
                        onboardingRequired = false
                    } label: {
                        Text("Continue")
                    }
                } else {
                    Button {
                        harness.pairControllers(selectedControllers)
                    } label: {
                        Text("Pair")
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.extraLarge)
            .font(.body.bold())
            .padding(.horizontal, 32)
            .disabled(selectedControllers.count < 2)
        }
        .onAppear { harness.connect() }
    }
    
    private var connectionInstructions: some View {
        VStack(alignment: .leading) {
            Text("Pair your harness")
                .font(.title3.bold())
            Text("Make sure both of the straps are powered on and keep your harness near your iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var selectionInstructions: some View {
        VStack(alignment: .leading) {
            Text("Pair your harness")
                .font(.title3.bold())
            Text("Multiple harnesses were found. Select your harness' straps from the list below.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private var connectedInfo: some View {
        VStack(alignment: .leading) {
            Text("Connected")
                .font(.title3.bold())
            Text("Your harness is now paired.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
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
    @Previewable @State var harness = SwiftSP621E()
    
    NavigationStack {
        PairingView()
    }
    .environment(harness)
}
