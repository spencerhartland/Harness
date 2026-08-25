//
//  ManageDevicesView.swift
//  Harness
//
//  Created by Spencer Hartland on 8/1/26.
//

import SwiftUI
import SwiftSP621E

struct ManageDevicesView: View {
    
    @Binding var harness: Harness
    
    @State private var shouldShowForgetConfirmation: Bool = false
    
    var body: some View {
        List {
            Section {
                let controllers = harness.controllers.sorted(by: { $0.value < $1.value })
                
                ForEach(controllers, id: \.key) { (id, name) in
                    NavigationLink(name) {
                        EditControllerNameView(id: id, name: name, harness: $harness)
                    }
                }
            } header: {
                Text("Controllers")
            }
        }
        .navigationTitle("Manage Harness")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { forgetHarnessButton }
        }
    }
    
    private var forgetHarnessButton: some View {
        Button("Forget") {
            shouldShowForgetConfirmation = true
        }
        .foregroundStyle(.red)
        .confirmationDialog("Forget", isPresented: $shouldShowForgetConfirmation) {
            Button("Forget", role: .destructive) { harness.forgetDevices() }
        } message: {
            Text("Forget this harness?")
        }
    }
}

#Preview {
    @Previewable @State var harness = Harness()
    
    NavigationStack {
        ManageDevicesView(harness: $harness)
    }
}
