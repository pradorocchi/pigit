import Foundation

public struct Failure: LocalizedError {
    public struct Repository {
        public static let duplicating = Failure("This is already a repository.")
        public static let invalid = Failure("This is not a repository.")
    }
    
    public var errorDescription: String? { return "Error: " + string }
    private let string: String
    private init(_ string: String) { self.string = string }
}