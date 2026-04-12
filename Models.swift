import Foundation

// MARK: - API Models

struct StoryRequest: Codable {
    let characters: String
    let moral: String
    let duration: String
}

struct StoryResponse: Codable {
    let story: String
}

// MARK: - Story Duration

enum StoryDuration: String, CaseIterable, Identifiable {
    case short, medium, long

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .short:  return "moon"
        case .medium: return "moon.stars"
        case .long:   return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .short:  return "~2 min"
        case .medium: return "~4 min"
        case .long:   return "~6 min"
        }
    }
}

// MARK: - Active Field

enum ActiveField: Hashable { case characters, moral }

// MARK: - API Error

enum APIError: LocalizedError {
    case serverUnreachable
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .serverUnreachable:
            return "Cannot reach the story server. Make sure it is running on port 8000."
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .decodingError:
            return "Received an unexpected response from the server."
        }
    }
}
