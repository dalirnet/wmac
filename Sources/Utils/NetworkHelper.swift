import Foundation

class NetworkHelper {
    static func getDefaultGateway() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        process.arguments = ["-nr"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }

            // Parse netstat output to find default gateway
            let lines = output.components(separatedBy: "\n")
            for line in lines {
                // Look for default route (0.0.0.0 or "default")
                if line.contains("default") || line.hasPrefix("0.0.0.0") {
                    let components = line.components(separatedBy: .whitespaces).filter {
                        !$0.isEmpty
                    }
                    // Gateway IP is typically the second column
                    if components.count >= 2 {
                        let gateway = components[1]
                        // Validate it's an IP address
                        if isValidIPAddress(gateway) {
                            return gateway
                        }
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    private static func isValidIPAddress(_ string: String) -> Bool {
        let ipPattern =
            "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let ipRegex = try? NSRegularExpression(pattern: ipPattern)
        let range = NSRange(location: 0, length: string.utf16.count)
        return ipRegex?.firstMatch(in: string, range: range) != nil
    }
}
