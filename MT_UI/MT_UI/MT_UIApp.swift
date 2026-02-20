// App entry point.
// Initializes the SwiftUI app and launches the Python backend process on startup.

import SwiftUI

// TODO: Instantiate BackendLauncher as a @StateObject.

// TODO: Use .onAppear to call BackendLauncher.launch().

// TODO: Use Scene's commands or WindowGroup's onReceive to call BackendLauncher.terminate()
//       when the app is about to quit (NSApplication.willTerminateNotification).

// TODO: Set minimum window size to something sensible (e.g. 800×500)
//       using .defaultSize or NSWindow configuration.

@main
struct MT_UIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
