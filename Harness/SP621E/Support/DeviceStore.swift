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

/// A store of Bluetooth devices.
public final class DeviceStore {
    private let defaults = UserDefaults.standard
    private static var savedDevicesKey: String = "SavedDevices"
    
    /// The identifiers of persisted devices.
    public private(set) var identifiers: [UUID] = []
    /// A boolean value indicating whether there are no persisted devices.
    public var isEmpty: Bool { identifiers.isEmpty }
    /// The number of persisted devices.
    public var deviceCount: Int { identifiers.count }
    
    public init() {
        guard let data = defaults.data(forKey: Self.savedDevicesKey),
              let decodedIdentifiers = try? JSONDecoder().decode([UUID].self, from: data) else {
            return
        }
        self.identifiers = decodedIdentifiers
    }
    
    /// Persists the specified devices.
    ///
    /// - Parameter devices: The devices to persist.
    public func save(_ devices: [Device]) {
        for device in devices { self.identifiers.append(device.id) }
        if let data = try? JSONEncoder().encode(self.identifiers) {
            defaults.set(data, forKey: Self.savedDevicesKey)
        }
    }
    
    /// Forgets all persisted devices.
    public func forgetDevices() {
        self.identifiers = []
        defaults.removeObject(forKey: Self.savedDevicesKey)
    }
}
