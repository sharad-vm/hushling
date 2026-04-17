import Foundation

// MARK: - API Service

actor APIService {
    static let shared = APIService()

    // Switch this to your Railway URL once deployed, e.g.:
    // "https://hushling-production.up.railway.app"
    // For local testing against the Windows backend:
    // "http://192.168.0.13:8000"
    private let baseURL = "https://web-production-7ecb1.up.railway.app"

    func generateStory(characters: String, moral: String, duration: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/generate-story") else {
            throw APIError.serverUnreachable
        }

        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            StoryRequest(characters: characters, moral: moral, duration: duration)
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.serverUnreachable
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.decodingError
        }

        guard http.statusCode == 200 else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(detail)
        }

        guard let result = try? JSONDecoder().decode(StoryResponse.self, from: data) else {
            throw APIError.decodingError
        }

        return result.story
    }
}
