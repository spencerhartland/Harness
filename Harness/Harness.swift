//
//  Harness.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import SwiftUI
import Observation

@Observable
final class Harness {
    private let coordinator = SP621ECoordinator()
    private var isApplyingRemoteState = false
    
    private var lastBrightnessUpdate: Date = .distantPast
    private var brightnessWorkItem: DispatchWorkItem?
    private let brightnessUpdateDelay: TimeInterval = 0.08
    
    private var lastColorUpdate: Date = .distantPast
    private var colorWorkItem: DispatchWorkItem?
    private let colorUpdateDelay: TimeInterval = 0.08
    
    var state: ConnectionState = .disconnected
    
    var isConnected: Bool { state == .connected }
    
    var isPoweredOn: Bool = false {
        didSet {
            guard !isApplyingRemoteState else { return }
            isPoweredOn ? coordinator.powerOn() : coordinator.powerOff()
        }
    }
    var brightness: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            setBrightness()
        }
    }
    var mode: SP621EMode = .solidColor {
        didSet {
            guard !isApplyingRemoteState else { return }
            setMode()
        }
    }
    var color: Color = Color(red: 255, green: 0, blue: 0) {
        didSet {
            guard !isApplyingRemoteState else { return }
            setColor()
        }
    }
    var effect: SP621EEffect = .rainbow {
        didSet {
            guard !isApplyingRemoteState else { return }
            setEffect()
        }
    }
    
    init() {
        // Start observing changes to BLE connection state
        coordinator.onStateChange = { [weak self] state in
            guard let self else { return }
            self.state = state
            if state != .connected {
                self.brightnessWorkItem?.cancel()
                self.colorWorkItem?.cancel()
            }
        }
        // Start observing changes to harness state
        coordinator.onPrimaryControllerStateChange = { [weak self] newState in
            guard let self else { return }
            self.isApplyingRemoteState = true
            self.isPoweredOn = newState.isOn
            self.brightness = Double(newState.brightness)
            self.mode = newState.mode
            self.color = newState.rgb.color
            if let effect = SP621EEffect(rawValue: newState.effectIndex) { self.effect = effect }
            self.isApplyingRemoteState = false
        }
    }
    
    func connect() { coordinator.connect() }
    
    private func setBrightness() {
        brightnessWorkItem?.cancel()
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastBrightnessUpdate)
        
        if elapsed >= brightnessUpdateDelay {
            lastBrightnessUpdate = .now
            coordinator.setBrightness(UInt8(brightness.rounded()))
        } else {
            let delay = brightnessUpdateDelay - elapsed
            let workItem = DispatchWorkItem { [weak self] in self?.setBrightness() }
            brightnessWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    private func setMode() {
        switch mode {
        case .solidColor:
            coordinator.setEffect(.disabled)
        case .dynamicEffect:
            coordinator.setEffect(effect)
        }
    }
    
    private func setColor() {
        colorWorkItem?.cancel()
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastColorUpdate)
        
        if elapsed >= colorUpdateDelay {
            lastColorUpdate = .now
            let (red, green, blue) = color.rgbBytes
            coordinator.setColor(
                red: red,
                green: green,
                blue: blue,
                brightness: UInt8(brightness.rounded())
            )
        } else {
            let delay = colorUpdateDelay - elapsed
            let workItem = DispatchWorkItem { [weak self] in self?.setColor() }
            colorWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    private func setEffect() {
        coordinator.setEffect(effect)
    }
}
