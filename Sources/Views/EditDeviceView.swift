import SwiftUI

struct EditDeviceView: View {
    @Binding var isPresented: Bool
    let device: Device
    @ObservedObject var ssh: SSH
    let settings: Settings
    @ObservedObject var deviceManager: DeviceManager
    let onComplete: (String) -> Void
    let onDelete: () -> Void

    @State private var macAddress: String = ""
    @State private var deviceLabel: String = ""
    @State private var deviceType: DeviceType = .other
    @State private var isSaving = false
    @State private var showingDeleteConfirm = false

    init(
        isPresented: Binding<Bool>, device: Device, ssh: SSH,
        settings: Settings, deviceManager: DeviceManager,
        onComplete: @escaping (String) -> Void, onDelete: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.device = device
        self.ssh = ssh
        self.settings = settings
        self.deviceManager = deviceManager
        self.onComplete = onComplete
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Device")
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
            .onAppear {
                macAddress = device.macAddress
                deviceLabel = device.userLabel
                deviceType = device.deviceType
            }

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
                            .disabled(true)

                        Text("Cannot be modified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingDeleteConfirm = true
                }) {
                    Text("Delete")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundColor(.red)

                Spacer()

                Button(action: {
                    saveChanges()
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        }
                        Text(isSaving ? "Saving..." : "Save")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(deviceLabel.isEmpty || isSaving)
            }
            .padding(24)
        }
        .frame(width: 480, height: 480)
        .alert("Delete Device", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                isPresented = false
                onDelete()
            }
        } message: {
            Text("This will remove and block the device.")
        }
    }

    private func saveChanges() {
        isSaving = true

        // Update label and type locally (MAC address is read-only)
        if let index = deviceManager.devices.firstIndex(where: { $0.id == device.id }) {
            var updatedDevice = deviceManager.devices[index]
            updatedDevice.userLabel = deviceLabel
            updatedDevice.deviceType = deviceType
            deviceManager.updateDevice(updatedDevice)
        }

        isPresented = false
        isSaving = false
    }
}
