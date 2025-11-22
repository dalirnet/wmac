import Foundation

// MARK: - SSH Command Result
/// Result type for SSH command execution
enum SSHCommandResult {
    case success(String)
    case failure(String)
}

// MARK: - SSH Error
/// Custom error type for SSH operations
enum SSHError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        }
    }
}

// MARK: - SSH Test Result
/// Result type for SSH connection testing
enum SSHTestResult {
    case success
    case failure(String)
}

// MARK: - SSH
/// Manages SSH connections, command execution, and connection testing
@MainActor
class SSH: ObservableObject {

    // MARK: - Published Properties
    @Published var isExecuting = false
    @Published var commandOutput: String = ""
    @Published var isTesting = false
    @Published var testResult: SSHTestResult?

    // MARK: - SSH Command Execution

    /// Execute a command on the remote terminal via SSH
    /// - Parameters:
    ///   - host: IP address of the terminal
    ///   - user: SSH username
    ///   - password: SSH password
    ///   - command: Command to execute on the terminal
    /// - Returns: Result containing success message or failure reason
    func executeCommand(
        host: String,
        user: String,
        password: String,
        command: String
    ) async -> SSHCommandResult {
        isExecuting = true
        commandOutput = ""

        // Validate inputs
        guard !host.isEmpty, !user.isEmpty, !password.isEmpty else {
            isExecuting = false
            return .failure("Invalid connection parameters")
        }

        // Get the path to the expect script from bundle resources
        guard let scriptPath = Bundle.main.path(forResource: "ssh_command", ofType: "exp") else {
            isExecuting = false
            return .failure("SSH script not found")
        }

        do {
            // Setup process to run expect script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/expect")
            process.arguments = [scriptPath, host, user, password, command]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()

            // Wait asynchronously for process completion
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    process.waitUntilExit()
                    continuation.resume()
                }
            }

            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""

            // Handle exit codes from expect script
            switch process.terminationStatus {
            case 0:
                let cleanedOutput = cleanCommandOutput(output, command: command)
                commandOutput = cleanedOutput
                isExecuting = false
                return .success(cleanedOutput)
            case 2:
                isExecuting = false
                return .failure("Authentication failed")
            case 3:
                isExecuting = false
                return .failure("Command timeout")
            case 4:
                isExecuting = false
                return .failure("Connection refused")
            case 6:
                isExecuting = false
                return .failure("Connection timeout")
            default:
                isExecuting = false
                return .failure("Command failed with exit code \(process.terminationStatus)")
            }

        } catch {
            isExecuting = false
            return .failure("Failed to execute command: \(error.localizedDescription)")
        }
    }

    // MARK: - Output Cleaning

    /// Clean up SSH command output by removing prompts and echo
    /// - Parameters:
    ///   - output: Raw output from SSH command
    ///   - command: The command that was executed
    /// - Returns: Cleaned output string
    private func cleanCommandOutput(_ output: String, command: String) -> String {
        var lines = output.components(separatedBy: .newlines)

        // Find where actual command output starts (after command echo)
        if let commandIndex = lines.firstIndex(where: { $0.contains(command) }) {
            lines = Array(lines.dropFirst(commandIndex + 1))
        }

        // Remove lines containing prompts and SSH connection info
        lines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty
                && !trimmed.hasSuffix("WAP>")
                && !trimmed.hasSuffix("#")
                && !trimmed.hasSuffix("$")
                && !line.contains("spawn ssh")
                && !line.contains("password:")
                && !line.contains("ERROR:")
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - WiFi Device Operations

    /// Fetch list of WiFi devices from the terminal
    /// - Parameters:
    ///   - host: IP address of the terminal
    ///   - user: SSH username
    ///   - password: SSH password
    /// - Returns: Result containing array of Device or error
    func fetchWiFiDevices(
        host: String,
        user: String,
        password: String
    ) async -> Result<[Device], SSHError> {
        let result = await executeCommand(
            host: host,
            user: user,
            password: password,
            command: "display wifi filter"
        )

        switch result {
        case .success(let output):
            let devices = parseWiFiFilterOutput(output)
            return .success(devices)
        case .failure(let error):
            return .failure(.commandFailed(error))
        }
    }

    /// Parse WiFi filter output into Device objects
    /// Expected format: "SSID-1  2a:77:3c:e8:bc:2e  Whitelist"
    /// - Parameter output: Raw output from display wifi filter command
    /// - Returns: Array of parsed Device objects
    private func parseWiFiFilterOutput(_ output: String) -> [Device] {
        var devices: [Device] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip header lines and empty lines
            if trimmed.isEmpty
                || trimmed.contains("SSID Index")
                || trimmed.contains("---")
                || trimmed.contains("success!")
            {
                continue
            }

            // Parse line: extract MAC address (second component)
            let components = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            if components.count >= 2 {
                let macAddress = String(components[1])
                let device = Device(macAddress: macAddress)
                devices.append(device)
            }
        }

        return devices
    }

    /// Add a WiFi device to the filter whitelist
    /// - Parameters:
    ///   - host: IP address of the terminal
    ///   - user: SSH username
    ///   - password: SSH password
    ///   - ssidIndex: SSID index (e.g., "SSID-1")
    ///   - macAddress: MAC address of the device to add
    /// - Returns: Result containing success message or error
    func addWiFiFilter(
        host: String,
        user: String,
        password: String,
        ssidIndex: String,
        macAddress: String
    ) async -> Result<String, SSHError> {
        // Extract numeric index from SSID-X format
        let index = ssidIndex.replacingOccurrences(of: "SSID-", with: "")
        let command = "add wifi filter index \(index) mac \(macAddress)"

        let result = await executeCommand(
            host: host,
            user: user,
            password: password,
            command: command
        )

        switch result {
        case .success(let output):
            if output.contains("success") {
                return .success("Device added successfully")
            } else {
                return .failure(.commandFailed("Failed to add device"))
            }
        case .failure(let error):
            return .failure(.commandFailed(error))
        }
    }

    /// Delete a WiFi device from the filter whitelist
    /// - Parameters:
    ///   - host: IP address of the terminal
    ///   - user: SSH username
    ///   - password: SSH password
    ///   - ssidIndex: SSID index (e.g., "SSID-1")
    ///   - macAddress: MAC address of the device to delete
    /// - Returns: Result containing success message or error
    func deleteWiFiFilter(
        host: String,
        user: String,
        password: String,
        ssidIndex: String,
        macAddress: String
    ) async -> Result<String, SSHError> {
        // Extract numeric index from SSID-X format
        let index = ssidIndex.replacingOccurrences(of: "SSID-", with: "")
        let command = "del wifi filter index \(index) mac \(macAddress)"

        let result = await executeCommand(
            host: host,
            user: user,
            password: password,
            command: command
        )

        switch result {
        case .success(let output):
            if output.contains("success") {
                return .success("Device deleted successfully")
            } else {
                return .failure(.commandFailed("Failed to delete device"))
            }
        case .failure(let error):
            return .failure(.commandFailed(error))
        }
    }

    // MARK: - Connection Testing

    /// Test SSH connection to validate credentials
    /// - Parameters:
    ///   - host: IP address of the terminal
    ///   - user: SSH username
    ///   - password: SSH password
    func testConnection(host: String, user: String, password: String) async {
        isTesting = true
        testResult = nil

        // Validate inputs
        guard !host.isEmpty else {
            testResult = .failure("IP address cannot be empty")
            isTesting = false
            return
        }

        guard !user.isEmpty else {
            testResult = .failure("SSH user cannot be empty")
            isTesting = false
            return
        }

        guard !password.isEmpty else {
            testResult = .failure("SSH password cannot be empty")
            isTesting = false
            return
        }

        // Validate IP address format
        let ipPattern =
            "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let ipRegex = try? NSRegularExpression(pattern: ipPattern)
        let range = NSRange(location: 0, length: host.utf16.count)

        if ipRegex?.firstMatch(in: host, range: range) == nil {
            testResult = .failure("Invalid IP address format")
            isTesting = false
            return
        }

        // Get the path to the expect script from bundle resources
        guard let scriptPath = Bundle.main.path(forResource: "ssh_command", ofType: "exp") else {
            testResult = .failure("SSH script not found")
            isTesting = false
            return
        }

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/expect")
            // Use empty command to just test the connection
            process.arguments = [scriptPath, host, user, password, ""]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()

            // Wait asynchronously without blocking the main thread
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    process.waitUntilExit()
                    continuation.resume()
                }
            }

            // Handle exit codes
            switch process.terminationStatus {
            case 0:
                testResult = .success
            case 2:
                testResult = .failure("Check user and password")
            case 3:
                testResult = .failure("Terminal did not respond")
            case 4:
                testResult = .failure("Connection was refused")
            case 5:
                testResult = .failure("Network is not reachable")
            case 6:
                testResult = .failure("Connection timed out")
            default:
                testResult = .failure("Connection could not establish")
            }

        } catch {
            testResult = .failure("Test execution has failed")
        }

        isTesting = false
    }
}
