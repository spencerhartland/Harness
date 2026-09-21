//
//  EffectPreset.swift
//  Harness
//
//  Created by Spencer Hartland on 9/13/26.
//

import SwiftUI
import SwiftSP621E

internal struct EffectPreset: Identifiable, Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case effect
        case effectSpeed
        case effectLength
    }
    
    var id: UUID
    var name: String
    var color: Color
    var effect: SP621EEffect
    var effectSpeed: Double
    var effectLength: Double
    
    init(
        _ name: String, 
        color: Color, 
        effect: SP621EEffect, 
        effectSpeed: Double, 
        effectLength: Double
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.effect = effect
        self.effectSpeed = effectSpeed
        self.effectLength = effectLength
    }
    
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try values.decode(UUID.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        
        let colorData = try values.decode(Data.self, forKey: .color)
        if let uiColor = try NSKeyedUnarchiver.unarchivedObject(
          ofClass: UIColor.self,
          from: colorData
        ) {
            self.color = Color(uiColor: uiColor)
        } else {
            self.color = Color(uiColor: .secondarySystemBackground)
        }
        
        self.effect = try values.decode(SP621EEffect.self, forKey: .effect)
        self.effectSpeed = try values.decode(Double.self, forKey: .effectSpeed)
        self.effectLength = try values.decode(Double.self, forKey: .effectLength)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        
        let colorData = try NSKeyedArchiver.archivedData(
            withRootObject: UIColor(self.color),
            requiringSecureCoding: false
        )
        try container.encode(colorData, forKey: .color)
        
        try container.encode(self.effect, forKey: .effect)
        try container.encode(self.effectSpeed, forKey: .effectSpeed)
        try container.encode(self.effectLength, forKey: .effectLength)
    }
}
