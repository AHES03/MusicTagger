// HTTP client for communicating with the local Python FastAPI backend.
// All requests target http://127.0.0.1:8000.
// Uses async/await + URLSession for non-blocking network calls.

import Foundation


struct SearchResponse: Decodable {
    let tracks: [Track]
    enum CodingKeys: String, CodingKey { case tracks = "Tracks" }
}
struct ReadMetadataResponse: Decodable {
    let file : MusicFile
    enum CodingKeys: String, CodingKey { case file = "Metadata" }
}

// MARK: - Error Handling

// Typed errors thrown by all APIClient methods.
enum APIError: Error, LocalizedError {
    case invalidResponse(String?)
    case decodingFailed
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let detail?):
            return "Invalid response: \(detail)"
        case .decodingFailed:
            return "Decoding failed"
        case .networkUnavailable:
            return "Network unavailable"
        default:
            return "An unexpected error occurred."
        }
    }
}

// Singleton — access via APIClient.shared from any view.
class APIClient{
    private static let urlBase: String = "http://127.0.0.1:8000"
    static let shared = APIClient()
    // MARK: - /search

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
        
            // TODO: Check the HTTP status code before decoding. If it's not 200,
            // decode the error detail from the response body and throw APIError.invalidResponse(_)
            // instead of attempting to decode SearchResponse — which will always fail on error responses.
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            return decoded.tracks
        
    }
    // MARK: - /read-metadata

    func readMetadata(filePath: String) async throws -> MusicFile{
        guard let url = URL(
           string: "\(Self.urlBase)/read-metadata"
        ) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",forHTTPHeaderField: "Content-Type")
        let body: [String:String] = ["file_path":filePath]
        request.httpBody = try JSONEncoder().encode(body)

           // TODO: Check the HTTP status code before decoding. If it's not 200,
           // decode the error detail from the response body and throw APIError.invalidResponse(_)
           // instead of attempting to decode ReadMetadataResponse — which will always fail on error responses.
        
           let (data, _) = try await URLSession.shared.data(for: request)
           let decoded = try JSONDecoder().decode(ReadMetadataResponse.self, from: data)
        print (decoded)
           return decoded.file
           
        }
    // MARK: - /write-metadata

    func writeMetadata(file: MusicFile) async throws{
        guard let url = URL(
            string: "\(Self.urlBase)/write-metadata"
        ) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(file)
        _ = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - /write-artwork

    // artworkPath accepts both local file paths and remote https:// URLs — backend handles both.
    func writeArtwork(filePath: String, artworkPath: String) async throws{
        guard let url = URL(
            string: "\(Self.urlBase)/write-artwork"
        ) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",forHTTPHeaderField: "Content-Type")
        let body: [String:String] = ["file_path":filePath, "artwork_path":artworkPath]
        request.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: request)
    }
    // MARK: - /health

    // Used by BackendLauncher to poll readiness before the UI becomes interactive.
    func healthCheck() async throws -> Bool{
        guard let url = URL(
           string: "\(Self.urlBase)/health"
        ) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}
