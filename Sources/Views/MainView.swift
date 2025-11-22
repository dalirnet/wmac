import SwiftUI

struct MainView: View {
    @StateObject private var settings = Settings()
    @StateObject private var ssh = SSH()
    @StateObject private var deviceManager = DeviceManager()
    @State private var showingSettings = false
    @State private var isLoadingDevices = false
    @State private var showingAddDevice = false
    @State private var selectedDevice: Device?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingHelp = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and action buttons
            HStack {
                // App Title
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("WMac")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("WiFi MAC Address Controller")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Add Device Button
                if !settings.ipAddress.isEmpty && !settings.sshUser.isEmpty
                    && !settings.sshPassword.isEmpty
                {
                    Button(action: { showingAddDevice = true }) {
                        Image(systemName: "plus.app.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Add device")
                }

                // Settings Button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(20)

            // Main content area
            VStack(spacing: 20) {
                if settings.ipAddress.isEmpty || settings.sshUser.isEmpty
                    || settings.sshPassword.isEmpty
                {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.7))

                        Text("MAC Address Controller")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Configure terminal settings to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Device List
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                            ForEach(deviceManager.devices) { device in
                                DeviceCard(
                                    device: device,
                                    deviceManager: deviceManager,
                                    onToggle: { isEnabled in
                                        if isEnabled {
                                            let result = await ssh.addWiFiFilter(
                                                host: settings.ipAddress,
                                                user: settings.sshUser,
                                                password: settings.sshPassword,
                                                ssidIndex: settings.ssidIndex,
                                                macAddress: device.macAddress
                                            )
                                            switch result {
                                            case .success:
                                                deviceManager.updateDeviceStatus(
                                                    macAddress: device.macAddress,
                                                    isEnabled: true)
                                            case .failure(let error):
                                                alertMessage = error.localizedDescription
                                                showingAlert = true
                                            }
                                        } else {
                                            let result = await ssh.deleteWiFiFilter(
                                                host: settings.ipAddress,
                                                user: settings.sshUser,
                                                password: settings.sshPassword,
                                                ssidIndex: settings.ssidIndex,
                                                macAddress: device.macAddress
                                            )
                                            switch result {
                                            case .success:
                                                deviceManager.updateDeviceStatus(
                                                    macAddress: device.macAddress,
                                                    isEnabled: false)
                                            case .failure(let error):
                                                alertMessage = error.localizedDescription
                                                showingAlert = true
                                            }
                                        }
                                    },
                                    onEdit: {
                                        selectedDevice = device
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }

            // Footer
            HStack {
                Text("Just a weekend hack for personal use and learning")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    if let url = URL(string: "https://github.com/dalirnet/wmac") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("GitHub")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("View on GitHub")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 920, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings, isPresented: $showingSettings)
        }
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceView(
                isPresented: $showingAddDevice,
                ssh: ssh,
                settings: settings,
                deviceManager: deviceManager,
                onComplete: { message in
                    alertMessage = message
                    showingAlert = true
                }
            )
        }
        .sheet(item: $selectedDevice) { device in
            EditDeviceView(
                isPresented: Binding(
                    get: { selectedDevice != nil },
                    set: { if !$0 { selectedDevice = nil } }
                ),
                device: device,
                ssh: ssh,
                settings: settings,
                deviceManager: deviceManager,
                onComplete: { message in
                    alertMessage = message
                    showingAlert = true
                },
                onDelete: {
                    Task {
                        if device.isEnabled {
                            let result = await ssh.deleteWiFiFilter(
                                host: settings.ipAddress,
                                user: settings.sshUser,
                                password: settings.sshPassword,
                                ssidIndex: settings.ssidIndex,
                                macAddress: device.macAddress
                            )
                            switch result {
                            case .success(let message):
                                deviceManager.removeDevice(macAddress: device.macAddress)
                                alertMessage = message
                                showingAlert = true
                            case .failure(let error):
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                        } else {
                            // Device is already disabled, just remove from list
                            deviceManager.removeDevice(macAddress: device.macAddress)
                        }
                    }
                }
            )
        }
        .alert("Message", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addDevice)) { _ in
            if !settings.ipAddress.isEmpty && !settings.sshUser.isEmpty
                && !settings.sshPassword.isEmpty
            {
                showingAddDevice = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelp)) { _ in
            showingHelp = true
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
        }
    }
}
