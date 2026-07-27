//
//  SP621E.swift
//  Harness
//
//  Created by Spencer Hartland on 7/12/26.
//

import Foundation
import CoreBluetooth

/// An object which provides functionality to communicate with and control
/// a single SP621E SPI LED controller via Bluetooth Low Energy.
final class SP621E: NSObject {
    
    private enum Bluetooth {
        static let frameHeader: UInt8 = 0xA0
        static let serviceUUID = CBUUID(string: "FFE0")
        static let characteristicUUID = CBUUID(string: "FFE1")

        enum Opcode: UInt8 {
            case power = 0x62
            case effect = 0x63
            case effectSpeed = 0x67
            case effectLength = 0x68
            case brightness = 0x66
            case color = 0x69
            case queryState = 0x70
        }
    }
    
    /// A mode of operation which determines if the controller displays a solid color or
    /// one of its built-in dynamic lighting effects.
    enum Mode: String {
        case solidColor = "Solid Color"
        case dynamicEffect = "Dynamic Effect"
    }
    
    /// A dynamic lighting effect.
    ///
    /// The SP621E has 142 built-in effects, each addrerssed by an 8-bit unsigned integer.
    enum Effect: UInt8 {
        case none = 0xBE
        case rainbow = 0x01
    }
    
    /// The user-configured state of the controller.
    struct State: Equatable {
        /// A boolean value indicating whether or not the LEDs connected to the controller are
        /// receiving power.
        var isOn: Bool
        /// The brightness value of the LEDs connected to the controller.
        var brightness: UInt8
        /// The current `Mode` in which the controller is operating.
        var mode: Mode
        /// The RGB values representing the current color of the LEDs connected to the controller.
        var rgb: RGB
        /// The index of one of the controller's built-in dynamic lighting effects.
        var effectIndex: UInt8
        /// The speed at which dynamic lighting effects are displayed by the controller.
        var effectSpeed: UInt8
        /// The duration of a single loop in a dynamic lighting effect.
        var effectLength: UInt8
        
        init(
            isOn: Bool,
            brightness: UInt8,
            mode: Mode,
            rgb: RGB,
            effectIndex: UInt8,
            effectSpeed: UInt8,
            effectLength: UInt8,
        ) {
            self.isOn = isOn
            self.brightness = brightness
            self.mode = mode
            self.rgb = rgb
            self.effectIndex = effectIndex
            self.effectSpeed = effectSpeed
            self.effectLength = effectLength
        }
        
        init?(from bytes: [UInt8]) {
            // Expect length of 20 bytes, header 0x53 0x43, frame index 0x01.
            guard bytes.count == 20, bytes[0] == 0x53, bytes[1] == 0x43, bytes[2] == 0x01 else {
                return nil
            }
            
            self.isOn = bytes[5] == 0x01
            self.brightness = bytes[9]
            self.mode = bytes[7] == Effect.none.rawValue ? .solidColor : .dynamicEffect
            self.rgb = RGB(red: bytes[12], green: bytes[13], blue: bytes[14])
            self.effectIndex = bytes[7]
            self.effectSpeed = bytes[10]
            self.effectLength = bytes[11]
        }
    }
    
    /// The peripheral associated with the controller.
    let peripheral: CBPeripheral
    
    /// The UUID associated with the controller.
    var identifier: UUID { peripheral.identifier }

    /// Tells the coordinator when there is a change to the connection state of the controller.
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    
    /// Tells the coordinator when the controller reports its state.
    ///
    /// The controller reports its state upon connection. The coordinator uses this state to
    /// synchronize its controllers.
    var onStateNotification: ((State) -> Void)?
    
    /// The connection state of the controller.
    private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            guard connectionState != oldValue else { return }
            onConnectionStateChange?(connectionState)
        }
    }
    
    private let queue: DispatchQueue
    private var writeableCharacteristic: CBCharacteristic?
    private var pendingWrites: [[UInt8]] = []

    init(peripheral: CBPeripheral, queue: DispatchQueue) {
        self.peripheral = peripheral
        self.queue = queue
        super.init()
    }
    
    /// Handles peripheral connection.
    ///
    /// Call from `centralManager(_:didConnect:)` to begin discovering the services and
    /// characteristics of the controller.
    func connect() {
        peripheral.delegate = self
        peripheral.discoverServices([Bluetooth.serviceUUID])
    }
    
    /// Handles peripheral disconnection.
    ///
    /// Call from `centralManager(_:didFailToConnect:error:)` and
    /// `centralManager(_:didDisconnectPeripheral:error:)` to update state following disconnect.
    func disconnect() {
        writeableCharacteristic = nil
        connectionState = .disconnected
    }

    // MARK: Commands -
    
    /// Request the controller's current state.
    func queryState() { sendCommand(for: .queryState, withBytes: [0x00]) }
    
    /// Power on the LEDs connected to the controller.
    func powerOn() { sendCommand(for: .power, withBytes: [0x01]) }
    
    /// Power off the LEDs connected to the controller.
    func powerOff() { sendCommand(for: .power, withBytes: [0x00]) }

    /// Set the LEDs connected to the controller to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the controller.
    func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        sendCommand(for: .color, withBytes: [red, green, blue, brightness])
    }

    /// Set the brightness of the LEDs connected to the controller.
    ///
    /// - Parameter level: The desired brightness.
    func setBrightness(_ level: UInt8) { sendCommand(for: .brightness, withBytes: [level]) }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    func setEffect(_ effect: Effect) { sendCommand(for: .effect, withBytes: [effect.rawValue]) }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    func setEffectSpeed(_ speed: UInt8) { sendCommand(for: .effectSpeed, withBytes: [speed]) }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    func setEffectLength(_ length: UInt8) { sendCommand(for: .effectLength, withBytes: [length]) }
    
    /// Applies the specified state to the controller.
    ///
    /// - Parameter state: The desired state of the controller.
    func applyState(_ state: State) {
        queue.async { [weak self] in
            guard let self else { return }

            sendCommand(for: .brightness, withBytes: [state.brightness], withResponse: true)

            switch state.mode {
            case .solidColor:
                sendCommand(for: .effect, withBytes: [Effect.none.rawValue], withResponse: true)
                sendCommand(
                    for: .color,
                    withBytes: [state.rgb.red, state.rgb.green, state.rgb.blue, state.brightness],
                    withResponse: true
                )
            case .dynamicEffect:
                let effect = Effect(rawValue: state.effectIndex) ?? .rainbow
                sendCommand(for: .effect, withBytes: [effect.rawValue], withResponse: true)
                sendCommand(for: .effectSpeed, withBytes: [state.effectSpeed], withResponse: true)
                sendCommand(for: .effectLength, withBytes: [state.effectLength], withResponse: true)
            }
            
            sendCommand(for: .power, withBytes: [state.isOn ? 0x01 : 0x00], withResponse: true)
        }
    }
    
    // MARK: Low-level Communication -
    
    private func sendCommand(for opcode: Bluetooth.Opcode, withBytes bytes: [UInt8], withResponse: Bool = false) {
        let commandHeader: [UInt8] = [Bluetooth.frameHeader, opcode.rawValue, UInt8(bytes.count)]
        let command: [UInt8] = commandHeader + bytes
        send(command, withResponse: withResponse)
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

// MARK: CBPeripheralDelegate -

extension SP621E: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == Bluetooth.serviceUUID {
            peripheral.discoverCharacteristics([Bluetooth.characteristicUUID], for: service)
        }
    }
    
    func peripheral(
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
            connectionState = .connected
            flushPending()
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == Bluetooth.characteristicUUID,
                let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        guard let deviceState = State(from: bytes) else {
            return
        }
        onStateNotification?(deviceState)
    }
    
    func peripheral(
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
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady — draining \(pendingWrites.count) pending")
        flushPending()
    }
}
