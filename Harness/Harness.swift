//
//  Harness.swift
//  Harness
//
//  Created by Spencer Hartland on 8/21/26.
//

import Foundation
import SwiftUI
import SwiftSP621E

@MainActor
@Observable
public final class Harness {
    private var manager = SP621EManager()
    
    private let brightnessThrottle = Throttle(interval: 0.08)
    private let colorThrottle = Throttle(interval: 0.08)
    private let effectSpeedThrottle = Throttle(interval: 0.08)
    private let effectLengthThrottle = Throttle(interval: 0.08)
    
    private var isApplyingRemoteState = false
    
    public private(set) var isPaired: Bool = false
    public private(set) var connectionState: ConnectionState = .disconnected
    public var isConnected: Bool { connectionState == .connected }
    public private(set) var discoveredDevices: [Device] = []
    public private(set) var controllers: [UUID: String] = [:]
    
    public var isOn: Bool = false {
        didSet {
            guard !isApplyingRemoteState else { return }
            isOn ? manager.powerOn() : manager.powerOff()
        }
    }
    
    public var brightness: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            brightnessThrottle.send {
                let value = UInt8(self.brightness.rounded())
                self.manager.setBrightness(value)
            }
        }
    }
    
    public var mode: SP621EMode = .solidColor {
        didSet {
            guard !isApplyingRemoteState else { return }
            switch mode {
            case .solidColor:
                effect = .none
            case .dynamicEffect:
                // TODO: When more modes are added, return to the last selected mode.
                effect = .rainbow
            }
        }
    }
    
    public var color: Color = Color(red: 255, green: 0, blue: 0) {
        didSet {
            guard !isApplyingRemoteState else { return }
            colorThrottle.send {
                let (red, green, blue) = self.color.rgbBytes
                let brightness = UInt8(self.brightness.rounded())
                self.manager.setColor(red: red, green: green, blue: blue, brightness: brightness)
            }
        }
    }
    
    public var effect: SP621EEffect = .none {
        didSet {
            guard !isApplyingRemoteState else { return }
            manager.setEffect(effect)
        }
    }
    
    public var effectSpeed: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            effectSpeedThrottle.send {
                let value = UInt8(self.effectSpeed.rounded())
                self.manager.setEffectSpeed(value)
            }
        }
    }
    
    public var effectLength: Double = 0.0 {
        didSet {
            guard !isApplyingRemoteState else { return }
            effectLengthThrottle.send {
                let value = UInt8(self.effectLength.rounded())
                self.manager.setEffectLength(value)
            }
        }
    }
    
    private var controllerState: SP621E.State {
        SP621E.State(
            isOn: isOn,
            brightness: UInt8(brightness.rounded()),
            mode: mode,
            rgb: color.rgbBytes,
            effectIndex: effect.rawValue,
            effectSpeed: UInt8(effectSpeed.rounded()),
            effectLength: UInt8(effectLength.rounded())
        )
    }
    
    init() {
        let manager = self.manager
        Task { @BluetoothActor in
            manager.delegate = self
        }
    }
    
    public func connect() { manager.connect() }
    
    public func pair(_ devices: [Device]) { manager.pair(devices) }
    
    public func forgetDevices() { manager.forgetDevices() }
    
    public func identifyController(with id: UUID, isOn: Bool) async throws {
        try await manager.identifyController(with: id, isOn: isOn)
    }
    
    public func renameController(with id: UUID, to name: String) async throws {
        try await manager.renameController(with: id, to: name)
    }
}

extension Harness: SP621EManagerDelegate {
    public func sp621eManagerDidUpdatePairingState(_ manager: SP621EManager) {
        let state = manager.isPaired
        Task { @MainActor in self.isPaired = state }
    }
    
    public func sp621eManagerDidUpdateConnectionState(_ manager: SP621EManager) {
        let state = manager.connectionState
        Task { @MainActor in
            self.connectionState = state
        }
    }
    
    public func sp621eManagerDidUpdateControllerState(_ manager: SP621EManager) {
        guard let state = manager.controllerState else { return }
        Task { @MainActor in
            self.isApplyingRemoteState = true
            self.brightness = Double(state.brightness)
            self.color = state.rgb.color
            self.mode = state.mode
            if let effect = SP621EEffect(rawValue: state.effectIndex) { self.effect = effect }
            self.effectSpeed = Double(state.effectSpeed)
            self.effectLength = Double(state.effectLength)
            self.isOn = state.isOn
            self.isApplyingRemoteState = false
        }
    }
    
    public func sp621eManager(_ manager: SP621EManager, didDiscover device: Device) {
        print("didDiscover device with ID: \(device.id.uuidString)")
        Task { @MainActor in self.discoveredDevices.append(device) }
    }
    
    public func sp621eManager(
        _ manager: SP621EManager,
        didConnectController id: UUID,
        name: String
    ) {
        Task { @MainActor in self.controllers[id] = name }
    }
    
    public func sp621eManager(
        _ manager: SP621EManager,
        didRenameController id: UUID,
        to name: String
    ) {
        Task { @MainActor in self.controllers[id] = name }
    }
    
    public func requestedControllerState() async -> SP621E.State {
        return await self.controllerState
    }
}
