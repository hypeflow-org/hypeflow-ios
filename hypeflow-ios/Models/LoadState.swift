import Foundation

enum LoadState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(Error)
}

extension LoadState {
    var caseName: String {
        switch self {
        case .idle: "idle"
        case .loading: "loading"
        case .success: "success"
        case .empty: "empty"
        case .error: "error"
        }
    }
}
