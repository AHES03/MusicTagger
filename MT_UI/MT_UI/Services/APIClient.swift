// HTTP client for communicating with the local Python FastAPI backend.
// All requests target http://127.0.0.1:8000.
// Uses async/await + URLSession for non-blocking network calls.

import Foundation

// TODO: Define base URL constant: "http://127.0.0.1:8000"

struct SearchResponse: Decodable {
    let tracks: [Track]
    enum CodingKeys: String, CodingKey { case tracks = "Tracks" }
}
class APIClient{
    // TODO: Create an APIClient class or struct.
    //       Consider making it a singleton (shared instance) or an @EnvironmentObject
    //       if it needs to be accessible across many views.
    
    private static let urlBase: String = "http://127.0.0.1:8000"
    static let shared = APIClient()
    // MARK: - /search

    // TODO: func searchTracks(query: String) async throws -> [Track]
    //       POST /search with body: { "query": query }
    //       Decode response as [Track] using JSONDecoder (snake_case → camelCase via keyDecodingStrategy).
    //       Throw a meaningful error if the backend returns non-200.
    func searchTracks(query: String) async throws -> [Track] {
        guard let url = URL(
            string: "\(Self.urlBase)/search"
        ) else {
            print("Invalid URL")
            return []
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",forHTTPHeaderField: "Content-Type")
        let body: [String:String] = ["query":query]
        request.httpBody = try JSONEncoder().encode(body)
        
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            return decoded.tracks
        
    }
    // MARK: - /read-metadata

    // TODO: func readMetadata(filePath: String) async throws -> MusicFile
    //       POST /read-metadata with body: { "file_path": filePath }
    //       Decode response as MusicFile.
    //       Called when the user selects a file in the file list.

    // MARK: - /write-metadata

    // TODO: func writeMetadata(file: MusicFile) async throws
    //       POST /write-metadata with body matching MetadataPayload (all optional fields).
    //       Encode MusicFile → JSON (camelCase → snake_case via keyEncodingStrategy).
    //       Throw on non-200 response.

    // MARK: - /write-artwork

    // TODO: func writeArtwork(filePath: String, artworkPath: String) async throws
    //       POST /write-artwork with body: { "file_path": filePath, "artwork_path": artworkPath }
    //       artworkPath can be a local file path OR a remote https:// URL (Spotify artwork URL).
    //       Backend handles both cases — no special logic needed here.

    // MARK: - /health

    // TODO: func healthCheck() async throws -> Bool
    //       GET /health
    //       Used by BackendLauncher to poll readiness before the UI becomes interactive.
    //       Return true if status 200, false or throw otherwise.

    // MARK: - Error Handling

    // TODO: Define an APIError enum conforming to LocalizedError.
    //       Cases to cover:
    //         - invalidResponse (non-200 with optional detail string from backend JSON)
    //         - decodingFailed
    //         - networkUnavailable
    
    

}
