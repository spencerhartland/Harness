//
//  ControlLabel.swift
//  Harness
//
//  Created by Spencer Hartland on 9/18/26.
//

import SwiftUI

struct ControlLabel: View {
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
