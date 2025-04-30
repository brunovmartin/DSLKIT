import SwiftUI

public typealias DSLComponentBuilder = (_ node: [String: Any], _ context: DSLContext) -> AnyView

public class DSLComponentRegistry {
    public static let shared = DSLComponentRegistry()

    private var components: [String: DSLComponentBuilder] = [:]

    private init() {}

    /// Registra um componente visual (ex: "text", "button")
    public func register(_ type: String, builder: @escaping DSLComponentBuilder) {
        components[type] = builder
    }

    /// Retorna o builder de um tipo
    public func resolve(_ type: String) -> DSLComponentBuilder? {
        guard let builder = components[type] else {
            return nil
        }
        return builder
    }

    /// Método auxiliar para registrar todos os componentes básicos
    public func registerDefaults() {
        HStackView.register()
        VStackView.register()
        TextView.register()
        ButtonView.register()
        TextFieldView.register()
        ListView.register()
        ImageView.register()
        DividerView.register()
        ScrollViewComponent.register()
        ToggleView.register()
        ZStackView.register()
        LabelView.register()
        MenuView.register()
    }
}
