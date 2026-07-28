//
//  SP621ECoordinator.swift
//  Harness
//
//  Created by Spencer Hartland on 7/15/26.
//

import Foundation
import CoreBluetooth

// TODO: Sync state when controller joins mid-session.

/// Coordinates the behavior of one or more SP621E SPI LED controllers.
final class SP621ECoordinator: NSObject {
    
    // MARK: Onboarding callbacks -
    /// Publishes changes to the coordinator's pairing state.
    var onPairingStateChange: ((Bool) -> Void)?
    /// Publishes a list of devices discovered by the coordinator.
    var didDiscover: (([Device]) -> Void)?
    
    // MARK: Ready state callbacks -
    /// Publishes changes to the coordinator's connection state.
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    /// Publishes changes to the state of the primary controller.
    ///
    /// The primary controller is the first to connect. The state of subsequent controllers is
    /// synchronized to the state of the primary controller upon connection.
    var onPrimaryControllerStateChange: ((SP621E.State) -> Void)?
    
    private(set) var connectionState: ConnectionState = .disconnected {
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

    private let deviceStore = DeviceStore()
    private var controllers: [UUID: SP621E] = [:]
    private var expectedControllerCount: Int { deviceStore.devices.count }
    
    private var discoveredDevices: [UUID: Device] = [:]
    
    private var primaryIdentifier: UUID?
    private var primaryState: SP621E.State?
    
    private let queue = DispatchQueue(label: "harness.ble")
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: queue)
    }
    
    // MARK: Pairing and Connection -
    
    /// Connects to controllers.
    ///
    /// If paired controllers exist, the coordinator connects directly to them.  Otherwise, the
    /// coordinator begins searching and publishes a list of discovered devices.
    func connect() {
        queue.async { [weak self] in
            guard let self, self.central.state == .poweredOn else { return }
            
            if self.deviceStore.isEmpty {
                self.searchForDevices()
            } else {
                self.connectPairedDevices()
            }
        }
    }
    
    /// Pairs the specified devices.
    ///
    /// - Parameter devices: The devices to pair.
    func pair(_ devices: [Device]) {
        queue.async { [weak self] in
            guard let self, !devices.isEmpty else { return }
            self.central.stopScan()
            self.deviceStore.save(devices)
            self.discoveredDevices.removeAll()
            self.connectPairedDevices()
        }
    }
    
    /// Forgets all paired devices.
    func forgetDevices() {
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
    
    // MARK: SP621E Commands -
    
    /// Power on the LEDs connected to the paired controllers.
    func powerOn()  { forEachController { $0.powerOn() } }
    
    /// Power off the LEDs connected to the paired controllers.
    func powerOff() { forEachController { $0.powerOff() } }
    
    /// Set the LEDs connected to the paired controllers to the specified RGB color and brightness.
    ///
    /// - Parameters:
    ///     - red: The red value of the desired color.
    ///     - green: The green value of the desired color.
    ///     - blue: The blue value of the desired color.
    ///     - brightness: The desired brightness of the LEDs connected to the paired controllers.
    func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) {
        forEachController { $0.setColor(red: red, green: green, blue: blue, brightness: brightness) }
    }
    
    /// Set the brightness of the LEDs connected to the paired controllers.
    ///
    /// - Parameter value: The desired brightness.
    func setBrightness(_ value: UInt8) { forEachController { $0.setBrightness(value) } }

    /// Display a built-in dynamic lighting effect.
    ///
    /// - Parameter effect: The desired effect.
    func setEffect(_ effect: SP621E.Effect) { forEachController { $0.setEffect(effect) } }
    
    /// Set the speed of built-in dynamic lighting effects.
    ///
    /// - Parameter speed: The desired speed at which effects will be displayed.
    func setEffectSpeed(_ speed: UInt8) { forEachController { $0.setEffectSpeed(speed) } }
    
    /// Set the length of built-in dynamic lighting effects.
    ///
    /// - Parameter length: The desired duration of a single loop of an effect.
    func setEffectLength(_ length: UInt8) { forEachController { $0.setEffectLength(length) } }
    
    private func forEachController(_ action: (SP621E) -> Void) {
        for controller in controllers.values {
            action(controller)
        }
    }
    
    // MARK: State management -
    
    private func updateConnectionState() {
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
        controller.onConnectionStateChange = { [weak self] _ in self?.updateConnectionState() }
        
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
        guard let primaryState else { return }
        controller.applyState(primaryState)
    }
    
    private func publishDiscoveredDevices() {
        let devices =  discoveredDevices.values.sorted { $0.rssi > $1.rssi }
        DispatchQueue.main.async { [weak self] in
            self?.didDiscover?(devices)
        }
    }
}

// MARK: CBCentralManagerDelegate -

extension SP621ECoordinator: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connect()
        default:
            connectionState = .disconnected
        }
    }
    
    func centralManager(
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
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        controllers[peripheral.identifier]?.connect()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateConnectionState()
        
        if central.state == .poweredOn, isPaired {
            central.scanForPeripherals(withServices: nil)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        controllers[peripheral.identifier]?.disconnect()
        updateConnectionState()
        
        if isPaired, deviceStore.identifiers.contains(peripheral.identifier) {
            central.connect(peripheral)
        }
    }
}
