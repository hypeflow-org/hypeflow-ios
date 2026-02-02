import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .httpError(let code):
            return "Server returned status \(code)."
        case .decodingError:
            return "Failed to read server response."
        case .networkError:
            return "Unable to connect. Check your network."
        }
    }
}

// MARK: - Protocol

protocol APIClientProtocol: Sendable {
    func fetchTrending() async throws -> [TrendDTO]
}

// MARK: - Implementation

final class APIClient: APIClientProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = "http://localhost:8080", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchTrending() async throws -> [TrendDTO] {
        guard let url = URL(string: "\(baseURL)/api/search/history/last?limit=15") else {
            throw APIError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode([TrendDTO].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
