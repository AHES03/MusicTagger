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
    // MARK: - Path Resolution

    private var backendPath: URL {
        var path = URL(fileURLWithPath: #file)
        path.deleteLastPathComponent()
        path.deleteLastPathComponent()
        path.deleteLastPathComponent()
        return path.appendingPathComponent("Backend")
    }

    // MARK: - Setup

    // Creates venv and installs requirements if venv doesn't exist yet.
    // Runs synchronously since uvicorn cannot start until setup is complete.
    private func setup() {
        let venvPython = backendPath.appendingPathComponent("venv/bin/python3")

        if !FileManager.default.fileExists(atPath: venvPython.path) {
            let createVenv = Process()
            createVenv.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            createVenv.arguments = ["-m", "venv", "venv"]
            createVenv.currentDirectoryURL = backendPath
            try? createVenv.run()
            createVenv.waitUntilExit()
        }

        let installDeps = Process()
        installDeps.executableURL = backendPath.appendingPathComponent("venv/bin/pip")
        installDeps.arguments = ["install", "-r", "requirements.txt"]
        installDeps.currentDirectoryURL = backendPath
        try? installDeps.run()
        installDeps.waitUntilExit()
    }

    // MARK: - Launch

    // Runs setup if needed, then starts uvicorn via Process().
    // Polls /health every 500ms until backend responds, then sets isOnline = true.
    func launch() {
        setup()

        process = Process()
        let pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe
        process?.arguments = ["-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"]
        process?.currentDirectoryURL = backendPath
        process?.executableURL = backendPath.appendingPathComponent("venv/bin/python3")

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
    // MARK: - Notes

    // NOTE: During development, the backend can be started manually in a terminal.
    //       BackendLauncher is primarily needed for the final bundled distribution.
    //       Consider a flag (e.g. DEBUG skip) to avoid double-launching during development.

}

