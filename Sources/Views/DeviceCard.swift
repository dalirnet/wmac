import SwiftUI

// MARK: - Device Card
/// Displays a single device with status, name, MAC address, and controls
struct DeviceCard: View {
    // MARK: - Properties
    let device: Device
    @ObservedObject var deviceManager: DeviceManager
    let onToggle: (Bool) async -> Void
    let onEdit: () -> Void

    @State private var isTogglingFilter = false
    @State private var currentTime = Date()

    // MARK: - Computed Properties

    /// Human-readable elapsed time since device was enabled
    private var elapsedTimeText: String {
        guard device.isEnabled, let enabledAt = device.enabledAt else {
            return ""
        }

        let elapsed = Int(currentTime.timeIntervalSince(enabledAt))

        if elapsed < 60 {
            return elapsed == 1 ? "1 second ago" : "\(elapsed) seconds ago"
        } else if elapsed < 3600 {
            let minutes = elapsed / 60
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if elapsed < 86400 {
            let hours = elapsed / 3600
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else {
            let days = elapsed / 86400
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }

    /// Format MAC address with emphasized first and last parts
    private var formattedMACAddress: some View {
        let parts = device.macAddress.uppercased().split(separator: ":")

        return HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                // First and last parts are bold with 80% opacity, middle parts are regular with 70% opacity
                Text(String(part))
                    .font(
                        .system(
                            size: 13,
                            weight: (index == 0 || index == parts.count - 1) ? .bold : .regular,
                            design: .monospaced)
                    )
                    .foregroundColor(.primary)
                    .opacity((index == 0 || index == parts.count - 1) ? 0.8 : 0.7)

                // Add colon separator (except after last part)
                if index < parts.count - 1 {
                    Text(":")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .opacity(0.5)
                }
            }
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Status indicator and toggle
            HStack {
                // Status icon and label
                Image(systemName: device.isEnabled ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundColor(device.isEnabled ? .green : .gray)
                    .font(.system(size: 18))

                Text(device.isEnabled ? "Allowed" : "Blocked")
                    .font(.caption)
                    .foregroundColor(device.isEnabled ? .primary : .secondary)

                // Elapsed time (only shown when enabled)
                Text(elapsedTimeText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                // Toggle switch
                Toggle(
                    "",
                    isOn: Binding(
                        get: { device.isEnabled },
                        set: { newValue in
                            Task {
                                isTogglingFilter = true
                                await onToggle(newValue)
                                isTogglingFilter = false
                            }
                        }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .disabled(isTogglingFilter)
            }

            Divider()

            // Device name with type icon
            HStack {
                Image(systemName: device.deviceType.iconName)
                    .foregroundColor(device.userLabel.isEmpty ? .secondary : .primary)
                    .opacity(device.userLabel.isEmpty ? 1.0 : 0.8)
                    .frame(width: 20)

                Text(device.userLabel.isEmpty ? "Unnamed" : device.userLabel)
                    .fontWeight(.medium)
                    .foregroundColor(device.userLabel.isEmpty ? .secondary : .primary)
                    .opacity(device.userLabel.isEmpty ? 1.0 : 0.8)
            }

            // MAC Address
            HStack(spacing: 8) {
                Image(systemName: "barcode")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .frame(width: 20)

                formattedMACAddress
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .opacity(device.isEnabled ? 1.0 : 0.6)
        // Loading overlay when toggling
        .overlay(
            Group {
                if isTogglingFilter {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        )
        // Double-click to edit
        .onTapGesture(count: 2) {
            onEdit()
        }
        // Start timer for elapsed time updates
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}
