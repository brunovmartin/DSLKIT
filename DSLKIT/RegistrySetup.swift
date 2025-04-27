import Foundation

public class RegistrySetup {
    public static func registerAll() {
        // Comandos
        VariableCommands.registerAll()
        ArrayCommands.registerAll()
        FlowCommands.registerAll()

        // Operadores
        StringOperators.registerAll()
        ArrayOperators.registerAll()
        LogicOperators.registerAll()
        MathOperators.registerAll()
        NumberOperators.registerAll()
        ConditionalOperators.registerAll()
        
        // Registra todos os componentes padrão definidos em DSLComponentRegistry
        DSLComponentRegistry.shared.registerDefaults()

    }
}
