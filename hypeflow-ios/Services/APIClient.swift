import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .httpError(let code):
            return "Server returned status \(code)."
        case .decodingError:
            return "Failed to read server response."
        case .encodingError:
            return "Failed to prepare the request."
        case .networkError:
            return "Unable to connect. Check your network."
        }
    }
}

// MARK: - Protocol

protocol APIClientProtocol: Sendable {
    func fetchTrending() async throws -> [TrendDTO]
    func fetchPopular(limit: Int) async throws -> [PopularWordDTO]
    func fetchTimeseries(_ request: TimeseriesRequestDTO) async throws -> TimeseriesResponseDTO
    func fetchSources() async throws -> [SourceDTO]
    func fetchTrends(mode: String, limit: Int, days: Int?,
                     startDate: String?, endDate: String?,
                     sources: [String]?) async throws -> TrendsResponseDTO
    func checkHealth() async -> Bool
}

// MARK: - Implementation

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://localhost:8080", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
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
            let decoder = JSONDecoder()
            return try decoder.decode([TrendDTO].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchPopular(limit: Int = 10) async throws -> [PopularWordDTO] {
        guard let url = URL(string: "\(baseURL)/api/search/history/popular?limit=\(limit)") else {
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
            let decoder = JSONDecoder()
            return try decoder.decode([PopularWordDTO].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchTimeseries(_ request: TimeseriesRequestDTO) async throws -> TimeseriesResponseDTO {
        guard let url = URL(string: "\(baseURL)/api/timeseries") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw APIError.encodingError(error)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
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
            let decoder = JSONDecoder()
            return try decoder.decode(TimeseriesResponseDTO.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchSources() async throws -> [SourceDTO] {
        guard let url = URL(string: "\(baseURL)/api/sources") else {
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
            let decoder = JSONDecoder()
            return try decoder.decode([SourceDTO].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchTrends(mode: String, limit: Int, days: Int?,
                     startDate: String?, endDate: String?,
                     sources: [String]?) async throws -> TrendsResponseDTO {
        guard var components = URLComponents(string: "\(baseURL)/api/trends") else {
            throw APIError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let days { queryItems.append(URLQueryItem(name: "days", value: "\(days)")) }
        if let startDate { queryItems.append(URLQueryItem(name: "startDate", value: startDate)) }
        if let endDate { queryItems.append(URLQueryItem(name: "endDate", value: endDate)) }
        if let sources, !sources.isEmpty {
            queryItems.append(URLQueryItem(name: "sources", value: sources.joined(separator: ",")))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw APIError.invalidURL }

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
            let decoder = JSONDecoder()
            return try decoder.decode(TrendsResponseDTO.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
