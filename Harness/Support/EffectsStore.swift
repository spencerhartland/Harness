//
//  EffectsStore.swift
//  Harness
//
//  Created by Spencer Hartland on 9/13/26.
//

import Foundation
import SwiftSP621E

@MainActor
@Observable
internal final class EffectsStore {
    private static let favoriteEffectsKey: String = "favoriteEffects"
    private static let presetsKey: String = "effectPresets"
    
    internal private(set) var favoriteEffects: Set<SP621EEffect> = []
    private var effectPresets: [UUID: EffectPreset] = [:]
    
    internal var presets: [EffectPreset] {
        [EffectPreset](effectPresets.values).sorted { $0.name < $1.name }
    }
    
    internal init() {
        guard let effectsData = UserDefaults.standard.data(forKey: Self.favoriteEffectsKey),
              let presetsData = UserDefaults.standard.data(forKey: Self.presetsKey),
              let decodedEffects = try? JSONDecoder().decode(Set<SP621EEffect>.self, from: effectsData),
              let decodedPresets = try? JSONDecoder().decode([UUID: EffectPreset].self, from: presetsData)
        else {
            return
        }
        self.favoriteEffects = decodedEffects
        self.effectPresets = decodedPresets
    }
    
    internal func favoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.insert(effect)
        saveFavoriteEffects()
    }
    
    internal func unfavoriteEffect(_ effect: SP621EEffect) {
        self.favoriteEffects.remove(effect)
        saveFavoriteEffects()
    }
    
    internal func savePreset(_ preset: EffectPreset) {
        self.effectPresets[preset.id] = preset
        savePresets()
    }
    
    internal func deletePreset(_ preset: EffectPreset) {
        self.effectPresets[preset.id] = nil
        savePresets()
    }
    
    internal func reset() {
        self.effectPresets = [:]
        savePresets()
    }
    
    private func saveFavoriteEffects() {
        guard let data = try? JSONEncoder().encode(self.favoriteEffects) else { return }
        UserDefaults.standard.set(data, forKey: Self.favoriteEffectsKey)
    }
    
    private func savePresets() {
        guard let data = try? JSONEncoder().encode(self.effectPresets) else { return }
        UserDefaults.standard.set(data, forKey: Self.presetsKey)
    }
}
