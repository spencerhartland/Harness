//
//  EditControllerNameView.swift
//  Harness
//
//  Created by Spencer Hartland on 8/25/26.
//

import SwiftUI
import SwiftSP621E

struct EditControllerNameView: View {
    @Environment(SwiftSP621E.self) private var harness
    @Environment(\.dismiss) private var dismiss
    
    private static let characterLimit: Int = 10
    
    private let controllerID: UUID
    @State private var controllerName: String
    @State private var exceededCharacterLimit: Bool = false
    
    init(id: UUID, name: String) {
        self.controllerID = id
        self.controllerName = name
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
            harness.identifyController(with: controllerID)
        }
    }
    
    private var confirmationButton: some View {
        Button(role: .confirm) {
            harness.changeControllerName(id: controllerID, name: controllerName)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditControllerNameView(id: .init(), name: "SP621E")
    }
}
