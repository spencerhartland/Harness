//
//  SP621ECoordinator.swift
//  Harness
//
//  Created by Spencer Hartland on 7/15/26.
//

import Foundation
import CoreBluetooth

public final class SP621ECoordinator: NSObject {
    public var onStateChange: ((ConnectionState) -> Void)?
    public var onPrimaryControllerStateChange: ((SP621E.State) -> Void)?
    public var currentSP621EState: (() -> SP621E.State?)?
    
    public private(set) var currentState: ConnectionState = .disconnected {
        didSet {
            guard currentState != oldValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onStateChange?(self.currentState)
            }
        }
    }
    
    private var central: CBCentralManager!
    private let deviceName = "pup-aphex"
    private let requiredControllers = 2
    
    // Connected SP621E SPI LED controllers
    private var controllers: [UUID: SP621E] = [:]
    // Primary controller (first to connect)
    private var primaryIdentifier: UUID?
    private var primaryState: SP621E.State?
    
    private let queue = DispatchQueue(label: "harness.ble")
    
    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: queue)
    }
    
    public func connect() {
        queue.async { [weak self] in
            guard let self, self.central.state == .poweredOn else { return }
            self.currentState = .connecting
            self.central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    public func powerOn()  { forEachController { $0.powerOn() } }
    
    public func powerOff() { forEachController { $0.powerOff() } }
    
    public func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        forEachController { $0.setColor(red: red, green: green, blue: blue, brightness: brightness) }
    }

    public func setBrightness(_ value: UInt8) {
        forEachController { $0.setBrightness(value) }
    }

    public func setEffect(_ effect: SP621E.Effect) {
        forEachController { $0.setEffect(effect) }
    }
    
    public func setEffectSpeed(_ speed: UInt8) {
        forEachController { $0.setEffectSpeed(speed) }
    }
    
    public func setEffectLength(_ length: UInt8) {
        forEachController { $0.setEffectLength(length) }
    }
    
    private func forEachController(_ action: (SP621E) -> Void) {
        for controller in controllers.values {
            action(controller)
        }
    }
    
    private func updateState() {
        let connectedCount = controllers.values.filter { $0.state == .connected }.count

        if connectedCount == requiredControllers {
            currentState = .connected
        } else if controllers.isEmpty {
            currentState = .disconnected
        } else {
            currentState = .connecting
        }
        
        if controllers.values.allSatisfy({ $0.state != .connected }) {
            primaryIdentifier = nil
            primaryState = nil
        }
    }

    private func subscribeToUpdates(from controller: SP621E) {
        controller.onStateChange = { [weak self] _ in
            self?.updateState()
        }
        
        controller.onStateNotification = { [weak self] deviceState in
            self?.handleStateNotification(from: controller, deviceState)
        }
    }

    private func handleStateNotification(from controller: SP621E, _ controllerState: SP621E.State) {
        // First controller to report state becomes primary.
        if primaryIdentifier == nil {
            primaryIdentifier = controller.identifier
            primaryState = controllerState
            DispatchQueue.main.async { [weak self] in
                self?.onPrimaryControllerStateChange?(controllerState)
            }
        } else if controller.identifier != primaryIdentifier {
            sync(controller)
        }
    }
    
    private func sync(_ controller: SP621E) {
        guard let initialState = primaryState else { return }        
        controller.applyState(initialState)
    }
}

extension SP621ECoordinator: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connect()
        default:
            currentState = .disconnected
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? ""
        guard name.contains(deviceName) else { return }
        
        // Ignore discovered peripherals
        guard controllers[peripheral.identifier] == nil else { return }
        
        let controller = SP621E(peripheral: peripheral, queue: queue)
        subscribeToUpdates(from: controller)
        controllers[peripheral.identifier] = controller
        
        controller.connect()
        central.connect(peripheral, options: nil)
        
        // Stop scanning once we've found the pair.
        if controllers.count >= requiredControllers {
            central.stopScan()
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        controllers[peripheral.identifier]?.handleConnection()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.handleDisconnection()
        updateState()
        
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.handleDisconnection()
        updateState()
        // TODO: attempt reconnect to this specific peripheral and sync upon connection.
    }
}
