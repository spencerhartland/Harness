//
//  DeviceStore.swift
//  Harness
//
//  Created by Spencer Hartland on 7/21/26.
//

import Foundation

/// A bluetooth device.
public struct Device: Codable, Identifiable, Equatable {
    /// An identifier that can be used to recognize devices that have previously connected.
    public let id: UUID
    /// A user-configurable name for the device.
    public var name: String
    /// The last known recieved signal strength indicator (RSSI) of the device.
    public var rssi: Int
    
    init(id: UUID, name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
    }
}

/// A store of bluetooth devices.
public final class DeviceStore {
    private let defaults = UserDefaults.standard
    private static var savedDevicesKey: String = "SavedDevices"
    
    /// Persisted bluetooth devices.
    public private(set) var devices: [Device] = []
    /// The identifiers of all persisted bluetooth devices.
    public var identifiers: [UUID] { devices.map(\.id) }
    /// A boolean value indicating whether there are no persisted devices.
    public var isEmpty: Bool { devices.isEmpty }
    
    public init() {
        guard let devicesData = defaults.data(forKey: Self.savedDevicesKey),
              let decodedDevices = try? JSONDecoder().decode([Device].self, from: devicesData) else {
            return
        }
        self.devices = decodedDevices
    }
    
    /// Persists the specified devices.
    ///
    /// - Parameter devices: The devices to persist.
    public func save(_ devices: [Device]) {
        self.devices = devices
        if let devicesData = try? JSONEncoder().encode(devices) {
            defaults.set(devicesData, forKey: Self.savedDevicesKey)
        }
    }
    
    /// Forgets all persisted devices.
    public func forgetDevices() {
        devices = []
        defaults.removeObject(forKey: Self.savedDevicesKey)
    }
}
