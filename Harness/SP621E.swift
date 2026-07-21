//
//  SP621E.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import Foundation
import CoreBluetooth

public final class SP621E: NSObject {
    public enum Mode: String {
        case solidColor = "Solid Color"
        case dynamicEffect = "Dynamic Effect"
    }
    
    public enum Effect: UInt8 {
        case none = 0xBE
        case rainbow = 0x01
    }
    
    public struct State: Equatable {
        var isOn: Bool
        var brightness: UInt8
        var mode: Mode
        var rgb: RGB
        var effectIndex: UInt8
        var effectSpeed: UInt8
        var effectLength: UInt8
        
        static func parse(_ bytes: [UInt8]) -> State? {
            // Expect: 20 bytes, header 0x53 0x43, frame index 0x01.
            guard bytes.count == 20, bytes[0] == 0x53, bytes[1] == 0x43, bytes[2] == 0x01 else {
                return nil
            }
            return State(
                isOn: bytes[5] == 0x01,
                brightness: bytes[9],
                mode: bytes[7] == Effect.none.rawValue ? .solidColor : .dynamicEffect,
                rgb: RGB(red: bytes[12], green: bytes[13], blue: bytes[14]),
                effectIndex: bytes[7],
                effectSpeed: bytes[10],
                effectLength: bytes[11],
            )
        }
    }
    
    private enum Bluetooth {
        static let frameHeader: UInt8 = 0xA0
        static let serviceUUID = CBUUID(string: "FFE0")
        static let characteristicUUID = CBUUID(string: "FFE1")

        enum Opcode {
            static let power: UInt8 = 0x62
            static let effect: UInt8 = 0x63
            static let effectSpeed: UInt8 = 0x67
            static let effectLength: UInt8 = 0x68
            static let brightness: UInt8 = 0x66
            static let color: UInt8 = 0x69
            static let queryState: UInt8 = 0x70
        }
    }
    
    public let peripheral: CBPeripheral
    public var identifier: UUID { peripheral.identifier }

    /// Called when the connection state changes.
    public var onStateChange: ((ConnectionState) -> Void)?
    /// Called when the controller reports its state (on connect).
    public var onStateNotification: ((State) -> Void)?

    public var deviceName: String = "SP621E"

    public private(set) var state: ConnectionState = .disconnected {
        didSet {
            guard state != oldValue else { return }
            onStateChange?(state)
        }
    }
    
    private let queue: DispatchQueue
    private var writeableCharacteristic: CBCharacteristic?
    private var pendingWrites: [[UInt8]] = []

    public init(peripheral: CBPeripheral, queue: DispatchQueue) {
        self.peripheral = peripheral
        self.queue = queue
        super.init()
        peripheral.delegate = self
    }
    
    public func connect() {
        state = .connecting
    }
    
    public func handleConnection() {
        peripheral.delegate = self
        peripheral.discoverServices([Bluetooth.serviceUUID])
    }
    
    public func handleDisconnection() {
        writeableCharacteristic = nil
        state = .disconnected
    }

    /// Ask the strip to report its current state.
    public func queryState() {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.queryState, 0x00])
    }
    
    /// Turn the strip on.
    public func powerOn() {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.power, 0x01, 0x01])
    }
    
    /// Turn the strip off.
    public func powerOff() {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.power, 0x01, 0x00])
    }

    /// Set a solid color with brightness.
    public func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.color, 0x04, red, green, blue, brightness])
    }

    /// Set brightness independently.
    public func setBrightness(_ level: UInt8) {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.brightness, 0x01, level])
    }

    /// Start a built-in dynamic effect.
    public func setEffect(_ effect: Effect) {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.effect, 0x01, effect.rawValue])
    }
    
    /// Set the speed of a built-in dynamic effect.
    public func setEffectSpeed(_ speed: UInt8) {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.effectSpeed, 0x01, speed])
    }
    
    /// Set the length of a built-in dynamic effect.
    public func setEffectLength(_ length: UInt8) {
        send([Bluetooth.frameHeader, Bluetooth.Opcode.effectLength, 0x01, length])
    }
    
    public func applyState(_ state: State) {
        queue.async { [weak self] in
            guard let self, let writeableCharacteristic else { return }

            send([Bluetooth.frameHeader, Bluetooth.Opcode.brightness, 0x01, state.brightness], withResponse: true)

            switch state.mode {
            case .solidColor:
                send([Bluetooth.frameHeader, Bluetooth.Opcode.effect, 0x01, Effect.none.rawValue], withResponse: true)
                send([Bluetooth.frameHeader, Bluetooth.Opcode.color, 0x04,
                       state.rgb.red, state.rgb.green, state.rgb.blue, state.brightness], withResponse: true)
            case .dynamicEffect:
                let effect = Effect(rawValue: state.effectIndex) ?? .rainbow
                send([Bluetooth.frameHeader, Bluetooth.Opcode.effect, 0x01, effect.rawValue], withResponse: true)
                send([Bluetooth.frameHeader, Bluetooth.Opcode.effectSpeed, 0x01, state.effectSpeed], withResponse: true)
                send([Bluetooth.frameHeader, Bluetooth.Opcode.effectLength, 0x01, state.effectLength], withResponse: true)
            }
            
            send([Bluetooth.frameHeader, Bluetooth.Opcode.power, 0x01, state.isOn ? 0x01 : 0x00], withResponse: true)
        }
    }

    private func send(_ bytes: [UInt8], withResponse: Bool = false) {
        queue.async { [weak self] in
            guard let self, let writeableCharacteristic else {
                self?.pendingWrites.append(bytes)
                return
            }
            let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
            if withResponse || self.peripheral.canSendWriteWithoutResponse {
                self.peripheral.writeValue(
                    Data(bytes),
                    for: writeableCharacteristic,
                    type: type
                )
            } else {
                self.pendingWrites.append(bytes)
            }
        }
    }

    private func flushPending() {
        guard let writeableCharacteristic else { return }
        while !pendingWrites.isEmpty, peripheral.canSendWriteWithoutResponse {
            let data = Data(pendingWrites.removeFirst())
            peripheral.writeValue(data, for: writeableCharacteristic, type: .withoutResponse)
        }
    }
}

// MARK: CBPeripheralDelegate

extension SP621E: CBPeripheralDelegate {
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == Bluetooth.serviceUUID {
            peripheral.discoverCharacteristics([Bluetooth.characteristicUUID], for: service)
        }
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == Bluetooth.characteristicUUID {
            writeableCharacteristic = characteristic
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            state = .connected
            flushPending()
        }
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == Bluetooth.characteristicUUID,
                let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        guard let deviceState = State.parse(bytes) else {
            return
        }
        onStateNotification?(deviceState)
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            print("Notify subscription failed: \(error)")
            return
        }
        if characteristic.isNotifying { queryState() }
    }
    
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady — draining \(pendingWrites.count) pending")
        flushPending()
    }
}
