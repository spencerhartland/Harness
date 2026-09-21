//
//  ManageDevicesView.swift
//  Harness
//
//  Created by Spencer Hartland on 8/1/26.
//

import SwiftUI
import SwiftSP621E

struct ManageDevicesView: View {
    @Environment(SwiftSP621E.self) private var harness
    
    @State private var shouldShowForgetConfirmation: Bool = false
    
    var body: some View {
        List {
            Section {
                let controllers = harness.controllers.sorted(by: { $0.value < $1.value })
                
                ForEach(controllers, id: \.key) { (id, name) in
                    NavigationLink(name) {
                        EditControllerNameView(id: id, name: name)
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
            Button("Forget", role: .destructive) { harness.forgetControllers() }
        } message: {
            Text("Forget this harness?")
        }
    }
}

#Preview {
    NavigationStack {
        ManageDevicesView()
    }
}
