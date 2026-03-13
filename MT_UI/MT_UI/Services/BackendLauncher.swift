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

    // Starts uvicorn via Process(), resolves Backend/ path using #file.
    // Polls /health every 500ms until backend responds, then sets isOnline = true.
    func launch() {

        process = Process()
        let pipe = Pipe()
        
        process?.standardOutput = pipe
        process?.standardError = pipe
        
        process?.arguments = ["-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"]
        process?.executableURL = URL(fileURLWithPath:"/usr/bin/python3")
        var currentPath = URL(fileURLWithPath: #file)
        currentPath.deleteLastPathComponent()
        currentPath.deleteLastPathComponent()
        currentPath.deleteLastPathComponent()
        currentPath.deleteLastPathComponent()
        let BackendPath = currentPath.appendingPathComponent("Backend")
        process?.currentDirectoryURL = BackendPath
        do {try process?.run()}
        catch{
            fatalError("Script(s) not found")
        }
        Task {
            while (!isOnline) {
                isOnline = try await APIClient.shared.healthCheck()
                try await Task.sleep(nanoseconds: 500_000_000)
            }
     
        }

    }
    // MARK: - Terminate

    // Terminates the uvicorn process. Hook into app lifecycle via willTerminate notification.
    func terminate() {
        process?.terminate()
    }
    // MARK: - Notes

    // NOTE: During development, the backend can be started manually in a terminal.
    //       BackendLauncher is primarily needed for the final bundled distribution.
    //       Consider a flag (e.g. DEBUG skip) to avoid double-launching during development.

}

