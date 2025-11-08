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
    func registerDefaultServices(
        persistenceController: PersistenceController,
        contactManager: ContactManager? = nil,
        templateManager: MessageTemplateManager? = nil,
        messagingService: MessagingService? = nil,
        messageMonitoringService: MessageMonitoringService? = nil
    ) {
        register(PersistenceController.self, service: persistenceController)

        let resolvedContactManager = contactManager ?? ContactManager(persistenceController: persistenceController)
        register(ContactManager.self, service: resolvedContactManager)

        let resolvedTemplateManager = templateManager ?? MessageTemplateManager(persistenceController: persistenceController)
        register(MessageTemplateManager.self, service: resolvedTemplateManager)

        if let messagingService {
            register(MessagingService.self, service: messagingService)
        } else if resolveOptional(MessagingService.self) == nil {
            register(MessagingService.self, service: MessagingService())
        }

        let resolvedMonitoringService = messageMonitoringService ?? MessageMonitoringService(persistenceController: persistenceController)
        register(MessageMonitoringService.self, service: resolvedMonitoringService)
    }

    private func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
}

// MARK: - Protocol for Services that need dependencies

protocol ServiceProtocol {
    static func create(container: ServiceContainer) -> Self
}
