// Manages launching and terminating the bundled Python backend process (uvicorn).
// Called on app start and on app quit.

import Foundation
import Combine

// @MainActor ensures @Published properties are updated on the main thread.
// ObservableObject allows SwiftUI views to react to isOnline changes.
@MainActor
class BackendLauncher: ObservableObject {

    @Published var isOnline : Bool = false
    var process: Process?

    // MARK: - Launch

    // Starts the PyInstaller-compiled backend binary bundled in the app's resources.
    // Polls /health every 500ms until backend responds, then sets isOnline = true.
    func launch() {
        process = Process()
        let pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe
        process?.executableURL = Bundle.main.resourceURL?.appendingPathComponent("backend")
        process?.arguments = ["--host", "127.0.0.1", "--port", "8000"]
        process?.currentDirectoryURL = Bundle.main.resourceURL

        do { try process?.run() } catch {
            fatalError("Failed to launch backend: \(error)")
        }

        Task {
            while (!isOnline) {
                do {
                    isOnline = try await APIClient.shared.healthCheck()
                } catch {
                    // Backend not ready yet — retry after 500ms
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    // MARK: - Terminate

    // Terminates the uvicorn process. Hook into app lifecycle via willTerminate notification.
    func terminate() {
        process?.terminate()
    }

    // NOTE: During development, start the backend manually in a terminal.
    //       BackendLauncher is primarily needed for the final bundled distribution.

}
