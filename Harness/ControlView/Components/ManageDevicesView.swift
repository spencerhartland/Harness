//
//  ManageDevicesView.swift
//  Harness
//
//  Created by Spencer Hartland on 8/1/26.
//

import SwiftUI

struct ManageDevicesView: View {
    
    @Binding var harness: Harness
    
    @State private var shouldShowForgetConfirmation: Bool = false
    
    var body: some View {
        List {
            Section {
                harness.controllers.forEach { (identifier, name) in
                    NavigationLink(name) { EditControllerNameView(for: controller) }
                }
            } header: {
                Text("Controllers")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Forget") {
                    shouldShowForgetConfirmation = true
                }
                .confirmationDialog("Forget", isPresented: $shouldShowForgetConfirmation) {
                    Button("Forget", role: .destructive) { harness.forget() }
                } message: {
                    Text("Forget this harness?")
                }
            }
        }
    }
    
    // TODO: Discover opcode for name change and implement in SP621E / Coordinator
    private struct EditControllerNameView: View {
        private let controllerID: UUID
        
        @State private var controllerName: String
        
        init(for controller: Device) {
            self.controllerID = controller.id
            self.controllerName = controller.name
        }
        
        var body: some View {
            List {
                Section {
                    TextField(
                        "Controller Name",
                        text: $controllerName,
                        prompt: Text("Controller Name")
                    )
                } header: {
                    Text("Controller Name")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var harness = Harness()
    
    NavigationStack {
        ManageDevicesView(harness: $harness)
    }
}
