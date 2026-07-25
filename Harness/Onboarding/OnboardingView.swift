//
//  OnboardingView.swift
//  Harness
//
//  Created by Spencer Hartland on 7/22/26.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.screenSize) private var screenSize
    @AppStorage(UserDefaults.Keys.username) private var username: String = ""
    
    @Binding var harness: Harness
    
    var body: some View {
        VStack {
            Image("HarnessAppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: screenSize.width / 6)
                .shadow(radius: 2)
            Text("Harness")
                .font(.largeTitle.bold())
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("What would you like to be called?")
                    .font(.title3.bold())
                
                Text("Your chosen name does not leave your device and is used only to personalize your experience.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                TextField("Name", text: $username, prompt: Text("Name"))
                    .textFieldStyle(.plain)
                    .padding()
                    .background {
                        Color(uiColor: .secondarySystemBackground)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical)
            }
            
            Spacer()
            
            NavigationLink {
                PairingView(harness: $harness)
            } label: {
                Text("Continue")
                    .font(.body.bold())
                    .padding(8)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .disabled(username.isEmpty)
        }
        .padding(32)
    }
}

#Preview {
    @Previewable @State var harness = Harness()
    
    NavigationStack {
        OnboardingView(harness: $harness)
    }
}
