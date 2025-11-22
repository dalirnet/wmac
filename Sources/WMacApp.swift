import SwiftUI

@main
struct WMacApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(replacing: .help) {
                Button("WMac Help") {
                    NotificationCenter.default.post(name: .openHelp, object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button(action: {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .keyboardShortcut(",", modifiers: .command)

                Button(action: {
                    NotificationCenter.default.post(name: .addDevice, object: nil)
                }) {
                    Label("Add Device", systemImage: "plus.app")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let addDevice = Notification.Name("addDevice")
    static let openHelp = Notification.Name("openHelp")
}
