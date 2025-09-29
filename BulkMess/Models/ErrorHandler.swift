import Foundation
import SwiftUI

// MARK: - Error Handler

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showErrorAlert = false

    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else {
                self.currentError = AppError.unknown(error.localizedDescription)
            }
            self.showErrorAlert = true
        }
    }

    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}

// MARK: - Centralized App Errors

enum AppError: Error, LocalizedError, Identifiable {
    case coreDataError(String)
    case networkError(String)
    case validationError(String)
    case permissionDenied(String)
    case fileError(String)
    case messagingError(String)
    case unknown(String)

    var id: String {
        return errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .coreDataError(let message):
            return "Database Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .permissionDenied(let message):
            return "Permission Required: \(message)"
        case .fileError(let message):
            return "File Error: \(message)"
        case .messagingError(let message):
            return "Messaging Error: \(message)"
        case .unknown(let message):
            return "Unexpected Error: \(message)"
        }
    }

    var failureReason: String? {
        switch self {
        case .coreDataError:
            return "There was an issue with the app's database."
        case .networkError:
            return "Please check your internet connection and try again."
        case .validationError:
            return "Please check your input and try again."
        case .permissionDenied:
            return "This feature requires permission to access your data."
        case .fileError:
            return "There was an issue accessing or saving files."
        case .messagingError:
            return "There was an issue sending messages."
        case .unknown:
            return "An unexpected error occurred."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .coreDataError:
            return "Try restarting the app. If the problem persists, contact support."
        case .networkError:
            return "Check your internet connection and try again."
        case .validationError:
            return "Please review and correct the highlighted fields."
        case .permissionDenied:
            return "Go to Settings to grant the required permissions."
        case .fileError:
            return "Check available storage space and try again."
        case .messagingError:
            return "Check your device's messaging capabilities and try again."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .coreDataError, .fileError:
            return .critical
        case .networkError, .messagingError:
            return .high
        case .permissionDenied:
            return .medium
        case .validationError:
            return .low
        case .unknown:
            return .high
        }
    }
}

enum ErrorSeverity {
    case low, medium, high, critical

    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }

    var icon: String {
        switch self {
        case .low:
            return "info.circle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content
            .alert(item: $errorHandler.currentError) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.errorDescription ?? "An unknown error occurred"),
                    primaryButton: .default(Text("OK")) {
                        errorHandler.clearError()
                    },
                    secondaryButton: .cancel(Text("Details")) {
                        // Could show detailed error view
                        errorHandler.clearError()
                    }
                )
            }
    }
}

extension View {
    func handleErrors(with errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlertView(errorHandler: errorHandler))
    }
}

// MARK: - Result Extensions

extension Result {
    func handleError(with errorHandler: ErrorHandler) {
        if case .failure(let error) = self {
            errorHandler.handle(error)
        }
    }
}

// MARK: - Error Conversion Extensions

extension ContactError {
    var asAppError: AppError {
        switch self {
        case .permissionDenied:
            return .permissionDenied("Contacts access is required to import contacts from your device.")
        case .importFailed:
            return .fileError("Failed to import contacts from device.")
        case .invalidPhoneNumber:
            return .validationError("Please enter a valid phone number.")
        case .saveFailed(let details):
            return .coreDataError("Failed to save contact: \(details)")
        }
    }
}

extension MessagingError {
    var asAppError: AppError {
        switch self {
        case .messageNotSupported:
            return .messagingError("SMS messaging is not supported on this device.")
        case .noViewController:
            return .messagingError("Unable to present message composer.")
        case .cancelled:
            return .messagingError("Message sending was cancelled.")
        case .sendFailed:
            return .messagingError("Failed to send message.")
        case .unknown:
            return .messagingError("An unknown messaging error occurred.")
        }
    }
}