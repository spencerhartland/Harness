//
//  SP621ECoordinator.swift
//  Harness
//
//  Created by Spencer Hartland on 7/15/26.
//

import Foundation
import CoreBluetooth

public final class SP621ECoordinator: NSObject {
    // Onboarding callbacks
    public var onPairingStateChange: ((Bool) -> Void)?
    public var didDiscover: (([Device]) -> Void)?
    
    // Ready state callbacks
    public var onConnectionStateChange: ((ConnectionState) -> Void)?
    public var onPrimaryControllerStateChange: ((SP621E.State) -> Void)?
    public var currentSP621EState: (() -> SP621E.State?)?
    
    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            guard connectionState != oldValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onConnectionStateChange?(self.connectionState)
            }
        }
    }
    
    private var isPaired: Bool = false {
        didSet {
            guard isPaired != oldValue else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onPairingStateChange?(self.isPaired)
            }
        }
    }
    
    private var central: CBCentralManager!
    private let deviceName = "pup-aphex" // TODO: Change to 'SP621E'
    
    // Storage for paired controllers
    private let deviceStore = DeviceStore()
    // Connected controllers
    private var controllers: [UUID: SP621E] = [:]
    // Expected number of connected controllers
    private var expectedControllerCount: Int { deviceStore.devices.count }
    
    private var discoveredDevices: [UUID: Device] = [:]
    
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
            
            if self.deviceStore.isEmpty {
                print("Searching for devices...")
                self.searchForDevices()
            } else {
                print("Connecting to paired devices...")
                self.connectPairedDevices()
            }
        }
    }
    
    public func pair(_ devices: [Device]) {
        queue.async { [weak self] in
            guard let self, !devices.isEmpty else { return }
            print("Attempting to pair...")
            self.central.stopScan()
            self.deviceStore.save(devices)
            self.discoveredDevices.removeAll()
            self.connectPairedDevices()
        }
    }
    
    public func forgetDevices() {
        queue.async { [weak self] in
            guard let self else { return }
            for controller in self.controllers.values {
                self.central.cancelPeripheralConnection(controller.peripheral)
            }
            self.controllers.removeAll()
            self.primaryIdentifier = nil
            self.primaryState = nil
            self.deviceStore.forgetDevices()
            self.searchForDevices()
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
    
    private func searchForDevices() {
        isPaired = false
        connectionState = .connecting
        discoveredDevices.removeAll()
        publishDiscoveredDevices()
        central.scanForPeripherals(withServices: nil)
    }
    
    private func connectPairedDevices() {
        isPaired = true
        connectionState = .connecting
        
        let knownDevices = central.retrievePeripherals(withIdentifiers: deviceStore.identifiers)
        for peripheral in knownDevices {
            guard controllers[peripheral.identifier] == nil else { continue }
            let controller = SP621E(peripheral: peripheral, queue: queue)
            subscribeToUpdates(from: controller)
            controllers[peripheral.identifier] = controller
            central.connect(peripheral)
        }
        
        let missingDevices = Set(deviceStore.identifiers).subtracting(controllers.keys)
        if !missingDevices.isEmpty {
            central.scanForPeripherals(withServices: nil)
        }
    }
    
    private func forEachController(_ action: (SP621E) -> Void) {
        for controller in controllers.values {
            action(controller)
        }
    }
    
    private func updateState() {
        let connectedCount = controllers.values.filter { $0.connectionState == .connected }.count

        if expectedControllerCount > 0, connectedCount == expectedControllerCount {
            connectionState = .connected
        } else if controllers.isEmpty {
            connectionState = .disconnected
        } else {
            connectionState = .connecting
        }
        
        if controllers.values.allSatisfy({ $0.connectionState != .connected }) {
            primaryIdentifier = nil
            primaryState = nil
        }
    }

    private func subscribeToUpdates(from controller: SP621E) {
        controller.onConnectionStateChange = { [weak self] _ in self?.updateState() }
        
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
    
    private func publishDiscoveredDevices() {
        let devices =  discoveredDevices.values.sorted {
            guard let device0RSSI = $0.rssi, let device1RSSI = $1.rssi else { return true }
            return device0RSSI > device1RSSI
        }
        DispatchQueue.main.async { [weak self] in
            self?.didDiscover?(devices)
        }
    }
}

extension SP621ECoordinator: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connect()
        default:
            connectionState = .disconnected
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
        
        if isPaired {
            guard deviceStore.identifiers.contains(peripheral.identifier),
                  controllers[peripheral.identifier] == nil else {
                return
            }
            let controller = SP621E(peripheral: peripheral, queue: queue)
            subscribeToUpdates(from: controller)
            controllers[peripheral.identifier] = controller
            central.connect(peripheral)
            
            let allDevicesConnected = Set(deviceStore.identifiers).isSubset(of: controllers.keys)
            if allDevicesConnected { central.stopScan() }
        } else {
            discoveredDevices[peripheral.identifier] = Device(
                id: peripheral.identifier,
                name: advName ?? peripheral.name ?? deviceName,
                rssi: RSSI.intValue
            )
            publishDiscoveredDevices()
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        controllers[peripheral.identifier]?.connect()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateState()
        
        if central.state == .poweredOn, isPaired {
            central.scanForPeripherals(withServices: nil)
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateState()
        
        if isPaired, deviceStore.identifiers.contains(peripheral.identifier) {
            central.connect(peripheral)
        }
    }
}
