import SwiftUI

struct ContentView: View {
    @StateObject private var settings = TerminalSettings()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and settings button
            HStack {
                HeaderView()

                Spacer()

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
            }
            .padding(20)

            // Main content area
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.7))

                    Text("WiFi MAC Address Controller")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if settings.ipAddress.isEmpty || settings.sshUser.isEmpty
                        || settings.sshPassword.isEmpty
                    {
                        Text("Configure terminal settings to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(minWidth: 600, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings, isPresented: $showingSettings)
        }
    }
}
