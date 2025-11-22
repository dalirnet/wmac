import Foundation

// MARK: - Device Type Enum
/// Represents different types of network devices
enum DeviceType: String, Codable, CaseIterable {
    case notebook = "Notebook"
    case desktop = "Desktop"
    case phone = "Phone"
    case tablet = "Tablet"
    case tv = "TV"
    case other = "Other"

    /// Returns the SF Symbol icon name for each device type
    var iconName: String {
        switch self {
        case .notebook: return "laptopcomputer"
        case .desktop: return "desktopcomputer"
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .tv: return "tv"
        case .other: return "antenna.radiowaves.left.and.right"
        }
    }
}

// MARK: - Device Model
/// Represents a single device with filtering capabilities
struct Device: Identifiable, Codable {
    let id: UUID
    let macAddress: String
    var userLabel: String
    var isEnabled: Bool
    var deviceType: DeviceType
    var enabledAt: Date?

    init(
        id: UUID = UUID(),
        macAddress: String,
        userLabel: String = "",
        isEnabled: Bool = true,
        deviceType: DeviceType = .other,
        enabledAt: Date? = nil
    ) {
        self.id = id
        self.macAddress = macAddress
        self.userLabel = userLabel
        self.isEnabled = isEnabled
        self.deviceType = deviceType
        self.enabledAt = enabledAt
    }

    /// Custom decoder to handle backward compatibility and missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode required fields
        id = try container.decode(UUID.self, forKey: .id)
        macAddress = try container.decode(String.self, forKey: .macAddress)
        userLabel = try container.decode(String.self, forKey: .userLabel)
        let decodedIsEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        isEnabled = decodedIsEnabled

        // Fallback to .other if deviceType is missing (backward compatibility)
        deviceType = (try? container.decode(DeviceType.self, forKey: .deviceType)) ?? .other

        // Handle enabledAt timestamp with backward compatibility
        if let decodedDate = try? container.decode(Date.self, forKey: .enabledAt) {
            enabledAt = decodedDate
        } else {
            // Set to current date for enabled devices without timestamp
            enabledAt = decodedIsEnabled ? Date() : nil
        }
    }
}

// MARK: - Device Manager
/// Manages the collection of devices and their persistence
@MainActor
class DeviceManager: ObservableObject {
    @Published var devices: [Device] = []
    private let devicesKey = "wifi_devices"

    init() {
        loadDevices()
    }

    /// Load devices from UserDefaults and persist any auto-generated timestamps
    func loadDevices() {
        guard let data = UserDefaults.standard.data(forKey: devicesKey),
            let decoded = try? JSONDecoder().decode([Device].self, from: data)
        else {
            return
        }

        devices = decoded
        // Save immediately to persist any newly set enabledAt timestamps from decoder
        saveDevices()
    }

    /// Save devices to UserDefaults
    func saveDevices() {
        guard let encoded = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(encoded, forKey: devicesKey)
    }

    /// Update an entire device by its ID
    func updateDevice(_ device: Device) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index] = device
        saveDevices()
    }

    /// Update device enabled status and timestamp
    func updateDeviceStatus(macAddress: String, isEnabled: Bool) {
        guard let index = devices.firstIndex(where: { $0.macAddress == macAddress }) else { return }
        devices[index].isEnabled = isEnabled
        devices[index].enabledAt = isEnabled ? Date() : nil
        saveDevices()
    }

    /// Merge fetched devices from terminal with local user data
    /// Preserves user labels, types, and timestamps for existing devices
    func mergeWithFetched(fetchedDevices: [Device]) {
        var updatedDevices: [Device] = []

        for fetched in fetchedDevices {
            if let existing = devices.first(where: { $0.macAddress == fetched.macAddress }) {
                // Preserve user data for existing devices
                var updated = fetched
                updated.userLabel = existing.userLabel
                updated.isEnabled = existing.isEnabled
                updated.deviceType = existing.deviceType
                updated.enabledAt = existing.enabledAt
                updatedDevices.append(updated)
            } else {
                // New device - set enabledAt if enabled
                var newDevice = fetched
                newDevice.enabledAt = newDevice.isEnabled ? Date() : nil
                updatedDevices.append(newDevice)
            }
        }

        devices = updatedDevices
        saveDevices()
    }

    /// Remove device by MAC address
    func removeDevice(macAddress: String) {
        devices.removeAll(where: { $0.macAddress == macAddress })
        saveDevices()
    }
}
