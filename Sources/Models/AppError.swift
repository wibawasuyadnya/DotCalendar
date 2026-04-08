import Foundation

enum AppError: LocalizedError {
    case heicCreationFailed
    case metadataFailed
    case heicFinalizeFailed

    var errorDescription: String? {
        switch self {
        case .heicCreationFailed: return "Failed to create HEIC image destination"
        case .metadataFailed: return "Failed to create appearance metadata"
        case .heicFinalizeFailed: return "Failed to finalize HEIC file"
        }
    }
}
