import Foundation

enum LoadState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(Error)
}
