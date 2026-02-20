// Manages launching and terminating the bundled Python backend process (uvicorn).
// Called on app start and on app quit.

import Foundation

// TODO: Create a BackendLauncher class.
//       Marked as @MainActor or uses DispatchQueue.main for any UI-facing state.

// MARK: - Launch

// TODO: func launch()
//       Locate the bundled Python interpreter and main.py inside the app bundle.
//       Use Process() to launch: `python3 -m uvicorn main:app --host 127.0.0.1 --port 8000`
//       Store the Process reference so it can be terminated later.
//       After launching, poll GET /health (via APIClient) until the backend responds,
//       then signal readiness to the UI (e.g. via a @Published isReady: Bool).

// MARK: - Terminate

// TODO: func terminate()
//       Call process.terminate() to shut down uvicorn when the app quits.
//       Hook this into the app lifecycle via .onReceive(NotificationCenter... willTerminate).

// MARK: - Notes

// NOTE: During development, the backend can be started manually in a terminal.
//       BackendLauncher is primarily needed for the final bundled distribution.
//       Consider a flag (e.g. DEBUG skip) to avoid double-launching during development.
