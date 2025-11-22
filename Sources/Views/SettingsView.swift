import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Binding var isPresented: Bool
    @StateObject private var ssh = SSH()
    @State private var showPassword = false
    @State private var showTestResult = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // IP Address
                    VStack(alignment: .leading, spacing: 8) {
                        Label("IP Address", systemImage: "network")
                            .font(.headline)

                        TextField("192.168.1.1", text: $settings.ipAddress)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Terminal network address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // SSH User
                    VStack(alignment: .leading, spacing: 8) {
                        Label("SSH User", systemImage: "person.fill")
                            .font(.headline)

                        TextField("root", text: $settings.sshUser)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Default is 'root'")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // SSH Password
                    VStack(alignment: .leading, spacing: 8) {
                        Label("SSH Password", systemImage: "key.fill")
                            .font(.headline)

                        HStack {
                            if showPassword {
                                TextField("Enter password", text: $settings.sshPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                            } else {
                                SecureField("Enter password", text: $settings.sshPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Check device label")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // SSID Index
                    VStack(alignment: .leading, spacing: 8) {
                        Label("SSID Index", systemImage: "wifi")
                            .font(.headline)

                        TextField("SSID-1", text: $settings.ssidIndex)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Format: SSID-1 to SSID-8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with Test and Done buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await ssh.testConnection(
                            host: settings.ipAddress,
                            user: settings.sshUser,
                            password: settings.sshPassword
                        )
                        showTestResult = true
                    }
                }) {
                    HStack(spacing: 6) {
                        if ssh.isTesting {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                        }
                        Text(ssh.isTesting ? "Testing" : "Test Connection")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(
                    settings.ipAddress.isEmpty || settings.sshUser.isEmpty
                        || settings.sshPassword.isEmpty || ssh.isTesting)

                Spacer()

                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
        .frame(width: 480, height: 600)
        .alert(isPresented: $showTestResult) {
            if let result = ssh.testResult {
                switch result {
                case .success:
                    return Alert(
                        title: Text("Connection Successful"),
                        message: Text("Terminal is ready to use"),
                        dismissButton: .default(Text("OK"))
                    )
                case .failure(let message):
                    return Alert(
                        title: Text("Connection Failed"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            return Alert(title: Text("Test Result"))
        }
    }
}
