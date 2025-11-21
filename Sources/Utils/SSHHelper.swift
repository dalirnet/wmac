import Foundation

enum SSHTestResult {
    case success
    case failure(String)
}

@MainActor
class SSHHelper: ObservableObject {
    @Published var isTesting = false
    @Published var testResult: SSHTestResult?

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

        // Escape password for shell
        let escapedPassword = password.replacingOccurrences(of: "'", with: "'\\''")

        // Create expect script for SSH connection - just verify connection, no commands needed
        let expectScript = """
            #!/usr/bin/expect -f
            set timeout 10

            spawn ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -p 22 \(user)@\(host)

            expect {
                "password:" {
                    send "\(escapedPassword)\\r"
                    expect {
                        "#" {
                            send "exit\\r"
                            exit 0
                        }
                        ">" {
                            send "exit\\r"
                            exit 0
                        }
                        "$" {
                            send "exit\\r"
                            exit 0
                        }
                        "Permission denied" {
                            exit 2
                        }
                        timeout {
                            exit 3
                        }
                    }
                }
                "Connection refused" {
                    exit 4
                }
                "No route to host" {
                    exit 5
                }
                timeout {
                    exit 6
                }
            }
            """

        let tempFile = NSTemporaryDirectory() + "wmac_ssh_test_\(UUID().uuidString).exp"

        do {
            try expectScript.write(toFile: tempFile, atomically: true, encoding: .utf8)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/expect")
            process.arguments = [tempFile]

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

            // Clean up temp file
            try? FileManager.default.removeItem(atPath: tempFile)

            // Handle exit codes
            switch process.terminationStatus {
            case 0:
                testResult = .success
            case 2:
                testResult = .failure("Authentication failed, check username and password")
            case 3:
                testResult = .failure("Terminal did not respond with expected prompt")
            case 4:
                testResult = .failure("Connection refused, SSH may not be enabled")
            case 5:
                testResult = .failure("No route to host, check network connection")
            case 6:
                testResult = .failure("Connection timeout, check IP address")
            default:
                testResult = .failure("Connection failed")
            }

        } catch {
            testResult = .failure("Failed to execute SSH test")
            try? FileManager.default.removeItem(atPath: tempFile)
        }

        isTesting = false
    }
}
