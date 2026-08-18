//
//  EditNameView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/31/26.
//

import SwiftUI

struct EditNameView: View {
    @AppStorage(UserDefaults.Keys.username) private var username: String = ""
    
    var body: some View {
        List {
            Section {
                TextField("Name", text: $username, prompt: Text("Name"))
            } header: {
                Text("What would you like to be called?")
            } footer: {
                Text("Your chosen name does not leave your device and is used only to personalize your experience.")
            }
        }
    }
}

#Preview {
    EditNameView()
}
