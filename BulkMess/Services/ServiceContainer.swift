import Foundation

// MARK: - Service Container for Dependency Injection

class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()

    private var services: [String: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, service: T) {
        let key = String(describing: type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let service: T = resolve(type) else {
            fatalError("Service of type \(type) not registered")
        }
        return service
    }
}

// MARK: - Service Registration Extension

extension ServiceContainer {
    func registerDefaultServices(persistenceController: PersistenceController) {
        register(PersistenceController.self, service: persistenceController)
        register(MessageMonitoringService.self, service: MessageMonitoringService())
        register(ContactManager.self, service: ContactManager(persistenceController: persistenceController))
        register(MessageTemplateManager.self, service: MessageTemplateManager(persistenceController: persistenceController))
    }
}

// MARK: - Protocol for Services that need dependencies

protocol ServiceProtocol {
    static func create(container: ServiceContainer) -> Self
}