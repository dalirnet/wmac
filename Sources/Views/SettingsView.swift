import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: TerminalSettings
    @Binding var isPresented: Bool
    @StateObject private var sshHelper = SSHHelper()
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Terminal Settings")
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
                    }

                    // SSH User
                    VStack(alignment: .leading, spacing: 8) {
                        Label("SSH User", systemImage: "person.fill")
                            .font(.headline)

                        TextField("root", text: $settings.sshUser)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Only 'root' user has SSH access")
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

                        Text("Find password on device back label")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Test Result
                    if let result = sshHelper.testResult {
                        HStack(alignment: .top, spacing: 12) {
                            switch result {
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connection Successful")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Text("Terminal is ready to use")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            case .failure(let message):
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connection Failed")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with Test and Done buttons
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await sshHelper.testConnection(
                            host: settings.ipAddress,
                            user: settings.sshUser,
                            password: settings.sshPassword
                        )
                    }
                }) {
                    HStack(spacing: 6) {
                        if sshHelper.isTesting {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                        }
                        Text(sshHelper.isTesting ? "Testing..." : "Test Connection")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(
                    settings.ipAddress.isEmpty || settings.sshUser.isEmpty
                        || settings.sshPassword.isEmpty || sshHelper.isTesting)

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
    }
}
