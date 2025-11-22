import SwiftUI

// MARK: - Help View
/// Displays helpful guide and instructions for using WMac
struct HelpView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("WMac Help")
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

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Quick Start
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Quick Start", icon: "play.circle")

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(text: "Configure terminal connection in Settings")
                            InfoRow(text: "Test connection to verify credentials")
                            InfoRow(text: "Add devices with MAC addresses")
                            InfoRow(text: "Toggle devices to control WiFi access")
                        }
                    }

                    Divider()

                    // Settings
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Connection Settings", icon: "gearshape")

                        VStack(alignment: .leading, spacing: 10) {
                            SettingItem(
                                label: "IP Address", value: "Terminal/router IP (e.g., 192.168.1.1)"
                            )
                            SettingItem(label: "SSH User", value: "Username for SSH authentication")
                            SettingItem(label: "SSH Password", value: "Password for authentication")
                            SettingItem(
                                label: "SSID Index", value: "WiFi network identifier (e.g., SSID-1)"
                            )
                        }
                    }

                    Divider()

                    // Managing Devices
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Device Management", icon: "antenna.radiowaves.left.and.right")

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(text: "Add Device: Press ⌘N or click + button")
                            InfoRow(text: "Edit Device: Double-click any device card")
                            InfoRow(text: "Toggle Access: Use switch on device card")
                            InfoRow(text: "Delete Device: Edit mode → Delete button")
                        }
                    }

                    Divider()

                    // MAC Address Format
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "MAC Address Format", icon: "barcode")

                        Text("AA:BB:CC:DD:EE:FF")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )

                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(text: "Six pairs of hexadecimal digits (0-9, A-F)")
                            InfoRow(text: "Separated by colons (:)")
                            InfoRow(text: "Case insensitive")
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                Text("WiFi MAC Address Controller")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
        .frame(width: 560, height: 680)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Setting Item
struct SettingItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundColor(.secondary)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}
