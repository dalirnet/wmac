import SwiftUI

struct AddDeviceView: View {
    @Binding var isPresented: Bool
    @ObservedObject var ssh: SSH
    let settings: Settings
    @ObservedObject var deviceManager: DeviceManager
    let onComplete: (String) -> Void

    @State private var macAddress = ""
    @State private var deviceLabel = ""
    @State private var deviceType: DeviceType = .other
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Device")
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
                    // Device Type
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Type", systemImage: "square.grid.2x2")
                            .font(.headline)

                        Picker("", selection: $deviceType) {
                            ForEach(DeviceType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.iconName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text("Select device category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Device Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Name", systemImage: "tag")
                            .font(.headline)

                        TextField("e.g., Living Room TV", text: $deviceLabel)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Use a recognizable name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // MAC Address
                    VStack(alignment: .leading, spacing: 8) {
                        Label("MAC Address", systemImage: "barcode")
                            .font(.headline)

                        TextField("aa:bb:cc:dd:ee:ff", text: $macAddress)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))

                        Text("Format: xx:xx:xx:xx:xx:xx")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with buttons
            HStack(spacing: 12) {
                Spacer()

                Button(action: {
                    addDevice()
                }) {
                    HStack(spacing: 6) {
                        if isAdding {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                        }
                        Text(isAdding ? "Adding..." : "Add Device")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(macAddress.isEmpty || deviceLabel.isEmpty || isAdding)
            }
            .padding(24)
        }
        .frame(width: 480, height: 580)
    }

    private func addDevice() {
        Task {
            isAdding = true

            let result = await ssh.addWiFiFilter(
                host: settings.ipAddress,
                user: settings.sshUser,
                password: settings.sshPassword,
                ssidIndex: settings.ssidIndex,
                macAddress: macAddress
            )

            switch result {
            case .success:
                // Refresh device list
                let fetchResult = await ssh.fetchWiFiDevices(
                    host: settings.ipAddress,
                    user: settings.sshUser,
                    password: settings.sshPassword
                )

                if case .success(let devices) = fetchResult {
                    deviceManager.mergeWithFetched(fetchedDevices: devices)
                    // Update label and type
                    if let index = deviceManager.devices.firstIndex(where: {
                        $0.macAddress == macAddress
                    }) {
                        var updatedDevice = deviceManager.devices[index]
                        updatedDevice.userLabel = deviceLabel
                        updatedDevice.deviceType = deviceType
                        deviceManager.updateDevice(updatedDevice)
                    }
                }

                isPresented = false

            case .failure(let error):
                onComplete(error.localizedDescription)
                isPresented = false
            }

            isAdding = false
        }
    }
}
