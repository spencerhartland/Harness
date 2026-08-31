//
//  EditControllerNameView.swift
//  Harness
//
//  Created by Spencer Hartland on 8/25/26.
//

import SwiftUI
import SwiftSP621E

struct EditControllerNameView: View {
    @Environment(\.dismiss) private var dismiss
    
    private static let characterLimit: Int = 10
    
    @Binding var harness: SwiftSP621E
    
    private let controllerID: UUID
    @State private var controllerName: String
    @State private var exceededCharacterLimit: Bool = false
    
    init(id: UUID, name: String, harness: Binding<SwiftSP621E>) {
        self.controllerID = id
        self.controllerName = name
        self._harness = harness
    }
    
    var body: some View {
        List {
            Section {
                TextField(
                    "Controller Name",
                    text: $controllerName,
                    prompt: Text("Controller Name")
                )
            } footer: {
                HStack {
                    Spacer()
                    Text("\(controllerName.count)/\(Self.characterLimit)")
                        .foregroundStyle(controllerName.count == Self.characterLimit ? .red : .secondary)
                        .shake(trigger: exceededCharacterLimit)
                }
            }
        }
        .navigationTitle("Edit Controller Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                identifyControllerButton
                confirmationButton
            }
        }
        .sensoryFeedback(.warning, trigger: controllerName) { _, newValue in
            newValue.count > Self.characterLimit
        }
        .onChange(of: controllerName) { oldValue, newValue in
            if newValue.count > Self.characterLimit {
                if exceededCharacterLimit == false { exceededCharacterLimit = true }
                controllerName = String(newValue.prefix(Self.characterLimit))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    exceededCharacterLimit = false
                }
            }
        }
    }
    
    private var identifyControllerButton: some View {
        Button("Identify", systemImage: "light.beacon.max.fill") {
            Task { try? await harness.identifyController(with: controllerID, isOn: harness.isOn) }
        }
    }
    
    private var confirmationButton: some View {
        Button(role: .confirm) {
            Task { try? await harness.renameController(with: controllerID, to: controllerName) }
            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var harness = SwiftSP621E()
    
    NavigationStack {
        EditControllerNameView(id: .init(), name: "SP621E", harness: $harness)
    }
}
