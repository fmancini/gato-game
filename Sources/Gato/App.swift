import AppKit
import SwiftUI

// Gato
//   Gato                      the app
//   APP_STORE=<file> Gato     use another database (tests, experiments)
//   APP_SNAPSHOT=<dir> Gato   save a PNG of every sidebar page and Settings tab in light and dark mode, then quit
//   Gato --selftest           run the self-test on a /tmp store and quit with 0 or 1 (tools/selftest.sh)
//   APP_ACCENT=<id> Gato      run with another accent from Theme.all (UI/Theme.swift)
//   APP_GRID=1 Gato           draw the 8 pt grid and the layout probes over the window

@main
struct GatoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Gato", id: "main") {
            ContentView()
                .environment(model)
                .themed()
                .overlay { if GridOverlay.enabled { GridOverlay() } }
                .frame(minWidth: 620, minHeight: 600)
        }
        .defaultSize(width: 820, height: 680)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Nueva partida") { model.newGame() }
                    .keyboardShortcut("n")
                Button("Reiniciar marcador") { model.resetScores() }
                    .keyboardShortcut("r")
            }
        }

        Settings {
            SettingsView()
                .environment(model)
                .themed()
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Started from a terminal, the process is not a foreground app yet.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// The self-test's result becomes the exit code, after a normal quit.
    func applicationWillTerminate(_ notification: Notification) {
        if SelfTest.requested { exit(SelfTest.exitCode) }
    }
}

/// Settings are in UserDefaults; this only tells test runs apart from real ones.
enum Store {
    /// True when APP_STORE points somewhere else (tests, snapshots).
    static var isOverridden: Bool {
        !(ProcessInfo.processInfo.environment["APP_STORE"] ?? "").isEmpty
    }
}
