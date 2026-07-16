//
//  SP621E.swift
//  BLE control layer for the SP621E (BanlanX) addressable-LED controller.
//
//  Protocol (reverse-engineered via PacketLogger capture of the BanlanX app):
//
//    Transport: write to characteristic FFE1 (service FFE0) as .withoutResponse
//    Frame:     A0 [opcode] [length] [payload...]
//
//    Power off:      A0 62 01 00
//    Power on:       A0 62 01 01
//    Solid color:    A0 69 04 RR GG BB LL   (RGB 0–255, LL brightness 0–255)
//    Brightness:     A0 66 01 LL            (standalone, 0–255)
//    Select effect:  A0 63 01 NN            (NN = effect index; rainbow = 01)
//
//  Usage:
//    let led = SP621E()
//    led.onStateChange = { state in print(state) }
//    led.start()                              // scans + auto-connects to an SP621E
//    // once .connected:
//    led.setColor(r: 255, g: 0, b: 255)       // purple
//    led.setEffect(.rainbow)
//    led.setBrightness(128)
//    led.setPower(false)
//

import Foundation
import CoreBluetooth

// MARK: - Protocol constants

private enum GATT {
    static let serviceUUID = CBUUID(string: "FFE0")
    static let characteristicUUID = CBUUID(string: "FFE1")
}

private enum Opcode: UInt8 {
    case power = 0x62
    case effect = 0x63
    case effectSpeed = 0x67
    case brightness = 0x66
    case color = 0x69
    case queryState = 0x70
}

private let frameHeader: UInt8 = 0xA0

// MARK: - Public types

public enum SP621EMode: String {
    case solidColor = "Solid Color"
    case dynamicEffect = "Dynamic Effect"
}

public enum SP621EEffect: UInt8 {
    case disabled = 0xBE
    case rainbow = 0x01
}

// MARK: - Controller

public final class SP621E: NSObject {
    public enum ConnectionState: Equatable {
        case disconnected, connecting, connected
    }
    
    public struct State: Equatable {
        public var isOn: Bool
        public var brightness: UInt8
        public var mode: SP621EMode
        public var rgb: RGB
        public var effectIndex: UInt8
        
        static func parse(_ bytes: [UInt8]) -> State? {
            // Expect: 20 bytes, header 0x53 0x43, frame index 0x01.
            guard bytes.count == 20, bytes[0] == 0x53, bytes[1] == 0x43, bytes[2] == 0x01 else {
                return nil
            }
            return State(
                isOn: bytes[5] == 0x01,
                brightness: bytes[9],
                mode: bytes[7] == SP621EEffect.disabled.rawValue ? .solidColor : .dynamicEffect,
                rgb: RGB(red: bytes[12], green: bytes[13], blue: bytes[14]),
                effectIndex: bytes[7],
            )
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
            DispatchQueue.main.async { [weak self] in
                self?.onStateChange?(self?.state ?? .disconnected)
            }
        }
    }
    
    private var writeableCharacteristic: CBCharacteristic?
    private var pendingWrites: [[UInt8]] = []

    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
    
    public func connect() {
        state = .connecting
    }
    
    public func handleConnection() {
        peripheral.delegate = self
        peripheral.discoverServices([GATT.serviceUUID])
    }
    
    public func handleDisconnection() {
        writeableCharacteristic = nil
        state = .disconnected
    }

    /// Ask the strip to report its current state.
    public func queryState() {
        send([frameHeader, Opcode.queryState.rawValue, 0x00])
    }
    
    /// Turn the strip on.
    public func powerOn() {
        send([frameHeader, Opcode.power.rawValue, 0x01, 0x01])
    }
    
    /// Turn the strip off.
    public func powerOff() {
        send([frameHeader, Opcode.power.rawValue, 0x01, 0x00])
    }

    /// Set a solid color with brightness.
    public func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        send([frameHeader, Opcode.color.rawValue, 0x04, red, green, blue, brightness])
    }

    /// Set brightness independently.
    public func setBrightness(_ level: UInt8) {
        send([frameHeader, Opcode.brightness.rawValue, 0x01, level])
    }

    /// Start a built-in dynamic effect.
    public func setEffect(_ effect: SP621EEffect) {
        send([frameHeader, Opcode.effect.rawValue, 0x01, effect.rawValue])
    }
    
    /// Set the speed of a built-in dynamic effect.
    public func setEffectSpeed(_ speed: UInt8) {
        send([frameHeader, Opcode.effectSpeed.rawValue, 0x01, speed])
    }

    private func send(_ bytes: [UInt8]) {
        guard let writeableCharacteristic else {
            self.pendingWrites.append(bytes)
            return
        }
        peripheral.writeValue(
            Data(bytes),
            for: writeableCharacteristic,
            type: .withoutResponse
        )
    }

    private func flushPending() {
        guard let writeableCharacteristic else { return }
        for bytes in pendingWrites {
            peripheral.writeValue(
                Data(bytes),
                for: writeableCharacteristic,
                type: .withoutResponse
            )
        }
        pendingWrites.removeAll()
    }
}

// MARK: CBPeripheralDelegate

extension SP621E: CBPeripheralDelegate {
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == GATT.serviceUUID {
            peripheral.discoverCharacteristics([GATT.characteristicUUID], for: service)
        }
    }
    
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == GATT.characteristicUUID {
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
        print("Parsing device state.")
        guard characteristic.uuid == GATT.characteristicUUID,
                let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        guard let deviceState = State.parse(bytes) else {
            print("Unable to parse device state.")
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onStateNotification?(deviceState)
        }
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
}
