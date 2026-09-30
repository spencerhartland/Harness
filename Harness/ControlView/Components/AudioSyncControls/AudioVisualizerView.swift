//
//  AudioVisualizerView.swift
//  Harness
//
//  Created by Spencer Hartland on 9/25/26.
//

import SwiftUI
import Charts

struct AudioVisualizerView: View {
    let levels: [Float]
    
    init(for levels: [Float]) {
        self.levels = levels
    }
    
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .red, location: 0),
                .init(color: .orange, location: 0.1),
                .init(color: .green, location: 0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .aspectRatio(3, contentMode: .fit)
        .mask {
            Chart(levels.indices, id: \.self) { index in
                AreaMark(
                    x: .value("Frequency", index),
                    y: .value("Magnitude", levels[index])
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                  MeshGradient(
                        width: 4,
                        height: 2,
                        points: [
                            [0,0], [0.15, 0], [0.85, 0], [1, 0],
                            [0, 1], [0.15, 1], [0.85, 1], [1, 1],
                        ],
                        colors: [
                            .primary.opacity(0), .primary.opacity(0.65), .primary.opacity(0.65), .primary.opacity(0),
                            .primary.opacity(0), .primary.opacity(0), .primary.opacity(0), .primary.opacity(0)
                        ]
                    )
                )
                
                LineMark(
                    x: .value("Frequency", index),
                    y: .value("Magnitude", levels[index])
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .primary.opacity(0), location: 0),
                            .init(color: .primary, location: 0.15),
                            .init(color: .primary, location: 0.85),
                            .init(color: .primary.opacity(0), location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .chartXScale(domain: 0...15)
            .chartYScale(domain: -10...265)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .animation(.easeOut, value: levels)
        }
    }
}

#Preview {
    @Previewable @State var previewLevels: [Float] = [
        127.41503, 127.41503, 255, 107.74201, 101.88021, 80.9071, 180.66491, 65,
        245.297844, 95.46173, 39.058865, 18.810339, 18.58319, 11.700314, 0.0, 1.0
    ]
    
    List {
        Section {
            AudioVisualizerView(for: previewLevels)
        }
    }
}
