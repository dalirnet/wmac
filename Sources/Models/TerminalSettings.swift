import Foundation

@MainActor
class TerminalSettings: ObservableObject {
    @Published var ipAddress: String {
        didSet {
            UserDefaults.standard.set(ipAddress, forKey: "terminal_ip")
        }
    }

    @Published var sshUser: String {
        didSet {
            UserDefaults.standard.set(sshUser, forKey: "terminal_user")
        }
    }

    @Published var sshPassword: String {
        didSet {
            UserDefaults.standard.set(sshPassword, forKey: "terminal_password")
        }
    }

    init() {
        // Try to get saved IP, otherwise use default gateway, fallback to 192.168.1.1
        if let savedIP = UserDefaults.standard.string(forKey: "terminal_ip") {
            self.ipAddress = savedIP
        } else if let gatewayIP = NetworkHelper.getDefaultGateway() {
            self.ipAddress = gatewayIP
        } else {
            self.ipAddress = "192.168.1.1"
        }

        self.sshUser = UserDefaults.standard.string(forKey: "terminal_user") ?? "root"
        self.sshPassword = UserDefaults.standard.string(forKey: "terminal_password") ?? ""
    }
}
