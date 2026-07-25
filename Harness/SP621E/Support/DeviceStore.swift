//
//  DeviceStore.swift
//  Harness
//
//  Created by Spencer Hartland on 7/21/26.
//

import Foundation

public struct Device: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var rssi: Int?
    
    init(id: UUID, name: String, rssi: Int? = nil) {
        self.id = id
        self.name = name
        self.rssi = rssi
    }
}

public final class DeviceStore {
    private let defaults = UserDefaults.standard
    private static var savedDevicesKey: String = "SavedDevices"
    
    public private(set) var devices: [Device] = []
    public var identifiers: [UUID] { devices.map(\.id) }
    public var isEmpty: Bool { devices.isEmpty }
    
    public init() {
        guard let devicesData = defaults.data(forKey: Self.savedDevicesKey),
              let decodedDevices = try? JSONDecoder().decode([Device].self, from: devicesData) else {
            return
        }
        self.devices = decodedDevices
    }
    
    public func save(_ devices: [Device]) {
        self.devices = devices
        if let devicesData = try? JSONEncoder().encode(devices) {
            defaults.set(devicesData, forKey: Self.savedDevicesKey)
        }
    }
    
    public func forgetDevices() {
        devices = []
        defaults.removeObject(forKey: Self.savedDevicesKey)
    }
}
