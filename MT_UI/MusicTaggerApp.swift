// App entry point.
// Initializes the SwiftUI app and launches the Python backend process on startup.

import SwiftUI

// BackendLauncher started on appear, terminated on NSApplication.willTerminateNotification.
// Window minimum size set via .frame(minWidth:minHeight:) in ContentView.

@main
struct MT_UIApp: App {
    @StateObject var backendLauncher = BackendLauncher()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // TODO: Check if ~/.config/musictagger/.env exists.
                    // If not, create the directory and write a template .env with empty values,
                    // then show an alert directing the user to Settings to fill in credentials.
                    backendLauncher.launch()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    backendLauncher.terminate()
                }
        }

        // TODO: Add a Settings scene (SettingsView) accessible via Cmd+, and the app menu.
        // SettingsView should read ~/.config/musictagger/.env, expose fields for
        // SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET, and write back on save.
    }
}
