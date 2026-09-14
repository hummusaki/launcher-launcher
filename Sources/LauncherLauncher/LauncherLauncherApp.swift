import SwiftUI

@main
struct LauncherLauncherApp: App {
    @State private var store = LauncherStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan for Launchers") { store.discover() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
