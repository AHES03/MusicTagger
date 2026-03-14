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
                    self.backendLauncher.launch()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)){_ in 
                    self.backendLauncher.terminate()
                }
        }
    }

    
}
