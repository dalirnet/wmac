import Foundation

// MARK: - Settings
/// Manages SSH connection settings for the terminal device
/// All settings are automatically persisted to UserDefaults
@MainActor
class Settings: ObservableObject {

    // MARK: - Published Properties

    /// IP address of the terminal device
    @Published var ipAddress: String {
        didSet {
            UserDefaults.standard.set(ipAddress, forKey: "terminal_ip")
        }
    }

    /// SSH username (typically "root" for most terminals)
    @Published var sshUser: String {
        didSet {
            UserDefaults.standard.set(sshUser, forKey: "terminal_user")
        }
    }

    /// SSH password for authentication
    @Published var sshPassword: String {
        didSet {
            UserDefaults.standard.set(sshPassword, forKey: "terminal_password")
        }
    }

    /// SSID index for WiFi filtering (e.g., "SSID-1" through "SSID-8")
    @Published var ssidIndex: String {
        didSet {
            UserDefaults.standard.set(ssidIndex, forKey: "terminal_ssid")
        }
    }

    // MARK: - Initialization

    /// Initialize settings from UserDefaults with intelligent defaults
    /// IP address attempts to use: 1) saved value, 2) default gateway, 3) fallback to 192.168.1.1
    init() {
        // Try to get saved IP, otherwise use default gateway, fallback to 192.168.1.1
        if let savedIP = UserDefaults.standard.string(forKey: "terminal_ip") {
            self.ipAddress = savedIP
        } else if let gatewayIP = Network.getDefaultGateway() {
            self.ipAddress = gatewayIP
        } else {
            self.ipAddress = "192.168.1.1"
        }

        self.sshUser = UserDefaults.standard.string(forKey: "terminal_user") ?? "root"
        self.sshPassword = UserDefaults.standard.string(forKey: "terminal_password") ?? ""
        self.ssidIndex = UserDefaults.standard.string(forKey: "terminal_ssid") ?? "SSID-1"
    }
}
