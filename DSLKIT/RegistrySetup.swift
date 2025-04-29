import Foundation

public class RegistrySetup {
    public static func registerAll() {
        DSLCommandRegistry.shared.registerDefaults()
        DSLOperatorRegistry.shared.registerDefaults()
        DSLComponentRegistry.shared.registerDefaults()

    }
}
