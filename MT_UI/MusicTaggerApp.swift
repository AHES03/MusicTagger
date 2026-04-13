// App entry point.
// Initializes the SwiftUI app and launches the Python backend process on startup.

import SwiftUI

// BackendLauncher started on appear, terminated on NSApplication.willTerminateNotification.
// Window minimum size set via .frame(minWidth:minHeight:) in ContentView.

struct SettingsView: View {
    @State var selection = 1
    var body: some View {
        TabView(selection: $selection) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape.2")
                }.tag(1)
            
            APISettingsView()
                .tabItem { Label("APIs", systemImage: "link") }
                .tag(2)
            
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Text("General Settings Content")
            .foregroundColor(.secondary)
    }
}

struct APISettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var clientID: String = ""
    @State private var clientSecret: String = ""
    private let envPath = ".config/musictagger/.env"
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("API Configuration")
                    .font(.system(size: 18, weight: .bold))
                Text("Manage third-party integrations and developer credentials.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.green)
                    Text("Spotify Integration")
                        .font(.system(size: 13, weight: .semibold))
                }
                VStack(spacing: 12) {
                    SettingsField(label: "SPOTIFY CLIENT ID", text: $clientID)
                    SettingsField(label: "SPOTIFY CLIENT SECRET", text: $clientSecret, isSecure: true)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 80)
                Button("Save Changes") {
                    let configFile = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(envPath)
                    try? "SPOTIFY_CLIENT_ID=\(clientID)\nSPOTIFY_CLIENT_SECRET=\(clientSecret)\n"
                        .write(to: configFile, atomically: true, encoding: .utf8)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 120)
            }
        }
        .padding(32)
        .onAppear {
            let configFile = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(envPath)
            if let contents = try? String(contentsOf: configFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let parts = line.components(separatedBy: "=")
                    if parts.count == 2 {
                        if parts[0] == "SPOTIFY_CLIENT_ID" { clientID = parts[1] }
                        if parts[0] == "SPOTIFY_CLIENT_SECRET" { clientSecret = parts[1] }
                    }
                }
            }
        }
    }
}

struct SettingsField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .textFieldStyle(.plain)
            .padding(8)
            .background(Color(white: 0.12))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

@main
struct MT_UIApp: App {
    @StateObject var backendLauncher = BackendLauncher()

    var body: some Scene {
        WindowGroup {
            ContentView(isBackendOnline: backendLauncher.isOnline)
                .onAppear {
                    let configFile = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent(".config/musictagger/.env")
                    if !FileManager.default.fileExists(atPath: configFile.path) {
                        try? FileManager.default.createDirectory(
                            at: configFile.deletingLastPathComponent(),
                            withIntermediateDirectories: true
                        )
                        try? "SPOTIFY_CLIENT_ID=\nSPOTIFY_CLIENT_SECRET=\n"
                            .write(to: configFile, atomically: true, encoding: .utf8)
                        // TODO: Show alert directing user to Settings (Cmd+,)
                    }
                    backendLauncher.launch()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    backendLauncher.terminate()
                }
        }

        Settings {
            SettingsView()
        }
    }
}
