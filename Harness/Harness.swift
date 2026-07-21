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
    
    private let brightnessThrottle = Throttle(interval: 0.08)
    private let colorThrottle = Throttle(interval: 0.08)
    private let effectSpeedThrottle = Throttle(interval: 0.08)
    private let effectLengthThrottle = Throttle(interval: 0.08)
    
    private var isApplyingRemoteState = false
    
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
    var mode: SP621E.Mode = .solidColor {
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
    var effect: SP621E.Effect = .none {
        didSet {
            guard !isApplyingRemoteState else { return }
            setEffect()
        }
    }
    var effectSpeed: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            setEffectSpeed()
        }
    }
    var effectLength: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            setEffectLength()
        }
    }
    
    init() {
        // Start observing changes to BLE connection state
        coordinator.onStateChange = { [weak self] state in
            guard let self else { return }
            self.state = state
            if state != .connected {
                brightnessThrottle.cancel()
                colorThrottle.cancel()
                effectSpeedThrottle.cancel()
                effectLengthThrottle.cancel()
            }
        }
        // Start observing changes to harness state
        coordinator.onPrimaryControllerStateChange = { [weak self] newState in
            guard let self else { return }
            self.isApplyingRemoteState = true
            self.brightness = Double(newState.brightness)
            self.color = newState.rgb.color
            self.mode = newState.mode
            if let effect = SP621E.Effect(rawValue: newState.effectIndex) { self.effect = effect }
            self.effectSpeed = Double(newState.effectSpeed)
            self.effectLength = Double(newState.effectLength)
            self.isPoweredOn = newState.isOn
            self.isApplyingRemoteState = false
        }
        
        coordinator.currentSP621EState = { [weak self] in self?.currentHarnessState }
    }
    
    func connect() { coordinator.connect() }
    
    private var currentHarnessState: SP621E.State {
        SP621E.State(
            isOn: isPoweredOn,
            brightness: UInt8(brightness.rounded()),
            mode: mode,
            rgb: RGB(from: color),
            effectIndex: effect.rawValue,
            effectSpeed: UInt8(effectSpeed.rounded()),
            effectLength: UInt8(effectLength.rounded())
        )
    }
    
    private func setBrightness() {
        brightnessThrottle.send { [weak self] in
            guard let self else { return }
            let value = UInt8(self.brightness.rounded())
            self.coordinator.setBrightness(value)
        }
    }
    
    private func setMode() {
        switch mode {
        case .solidColor:
            effect = .none
        case .dynamicEffect:
            // TODO: When more modes are added, return to the last selected mode.
            effect = .rainbow
        }
    }
    
    private func setColor() {
        colorThrottle.send { [weak self] in
            guard let self else { return }
            let (red, green, blue) = self.color.rgbBytes
            let brightness = UInt8(self.brightness.rounded())
            self.coordinator.setColor(red: red, green: green, blue: blue, brightness: brightness)
        }
    }
    
    private func setEffect() {
        coordinator.setEffect(effect)
    }
    
    private func setEffectSpeed() {
        effectSpeedThrottle.send { [weak self] in
            guard let self else { return }
            let value = UInt8(self.effectSpeed.rounded())
            self.coordinator.setEffectSpeed(value)
        }
    }
    
    private func setEffectLength() {
        effectLengthThrottle.send { [weak self] in
            guard let self else { return }
            let value = UInt8(self.effectLength.rounded())
            self.coordinator.setEffectLength(value)
        }
    }
}

final class Throttle {
    private let interval: TimeInterval
    private var lastFire: Date = .distantPast
    private var pending: DispatchWorkItem?

    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func send(_ action: @escaping () -> Void) {
        pending?.cancel()
        let elapsed = Date().timeIntervalSince(lastFire)
        if elapsed >= interval {
            lastFire = .now
            action()
        } else {
            let work = DispatchWorkItem { [weak self] in
                self?.lastFire = .now
                action()
            }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval - elapsed), execute: work)
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
    }
}
