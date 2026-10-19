//
//  FilterMenu.swift
//  Harness
//
//  Created by Spencer Hartland on 10/17/26.
//

import SwiftUI
import SwiftSP621E

enum AudioEffectFilter: String, CaseIterable, Identifiable {
    case showAll = "Show All"
    case showMulticolorOnly = "Multicolor"
    case showSingleColorOnly = "Single Color"
    
    var id: String { self.rawValue }
}

struct FilterMenu: View {
    @Binding var filterColors: Set<SP621EEffect.StandardColor>
    @Binding var filterEffectPattern: SP621EEffect.Pattern?
    @Binding var audioEffectFilter: AudioEffectFilter
    
    private var activeFiltersCount: Int {
        var result: Int = 0
        if let filterEffectPattern { result += 1 }
        if !filterColors.isEmpty { result += filterColors.count }
        if audioEffectFilter != .showAll { result += 1 }
        return result
    }
    
    typealias EffectType = SP621EEffect.EffectType
    let effectType: EffectType
    
    init(
        type: EffectType = .standard,
        colors: Binding<Set<SP621EEffect.StandardColor>>,
        pattern: Binding<SP621EEffect.Pattern?>,
        audioEffectFilter: Binding<AudioEffectFilter>,
    ) {
        self.effectType = type
        self._filterColors = colors
        self._filterEffectPattern = pattern
        self._audioEffectFilter = audioEffectFilter
    }
    
    var body: some View {
        Menu {
            if effectType == .standard {
                standardEffectFilterMenu
            } else {
                audioEffectFilterMenu
            }
        } label: {
            HStack {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
                    .labelStyle(.iconOnly)
                if activeFiltersCount > 0 {
                    Text("\(activeFiltersCount)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .menuActionDismissBehavior(.disabled)
        .buttonStyle(.glass)
    }
    
    @ViewBuilder private var audioEffectFilterMenu: some View {
        let selection = Binding<AudioEffectFilter>(
            get: { self.audioEffectFilter },
            set: { newValue in
                if newValue == audioEffectFilter {
                    self.audioEffectFilter = .showAll
                } else {
                    self.audioEffectFilter = newValue
                }
            }
        )
        
        Picker("Multicolor", selection: selection) {
            ForEach(AudioEffectFilter.allCases) { filter in
                if filter != .showAll {
                    Text(filter.rawValue).tag(filter)
                }
            }
        }
    }
    
    @ViewBuilder private var standardEffectFilterMenu: some View {
        Section {
            Menu {
                ForEach(SP621EEffect.StandardColor.allCases) { color in
                    let colorIsFiltered: Bool = filterColors.contains(color)
                    
                    Button {
                        if colorIsFiltered {
                            filterColors.remove(color)
                        } else {
                            filterColors.insert(color)
                        }
                    } label: {
                        var systemImage: String {
                            colorIsFiltered ? "checkmark.circle" : "circle.fill"
                        }
                        Label(color.name, systemImage: systemImage)
                    }
                    .tint(color.color)
                }
            } label: {
                Text("Color")
                if !filterColors.isEmpty {
                    var status: String {
                        if filterColors.count == 1,
                           let color = filterColors.first {
                            return color.name
                        } else {
                            return "\(filterColors.count) selected"
                        }
                    }
                    
                    Text(status)
                }
            }
            
            Menu {
                let selection = Binding<SP621EEffect.Pattern?>(
                    get: { self.filterEffectPattern },
                    set: { newValue in
                        if let filterEffectPattern,
                           newValue == filterEffectPattern {
                            self.filterEffectPattern = nil
                        } else {
                            self.filterEffectPattern = newValue
                        }
                    }
                )
                
                Picker("Pattern", selection: selection) {
                    ForEach(SP621EEffect.Pattern.standardPatterns) { pattern in
                        Text(pattern.name).tag(pattern)
                    }
                }
            } label: {
                Text("Pattern")
                if let filterEffectPattern { Text(filterEffectPattern.name) }
            }
        }
        
        if activeFiltersCount > 0 {
            Section {
                Button("Remove Filters") {
                    filterColors = []
                    filterEffectPattern = nil
                }
            }
        }
    }
}
