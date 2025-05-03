import Foundation

public class RegistrySetup {
    public static func registerAll() {
        DSLCommandRegistry.shared.registerDefaults()
        DSLOperatorRegistry.shared.registerDefaults()
        DSLComponentRegistry.shared.registerDefaults()
        
        // Registrar componentes de UI
        ButtonView.register()
        TextFieldView.register()
        TextView.register()
        ImageView.register()
        ListView.register()
        PickerView.register()
        SpacerView.register()
        ToggleView.register()
        MenuView.register()
        LabelView.register()
        ZStackView.register()
        VStackView.register()
        HStackView.register()
        ScrollViewComponent.register()
        DividerView.register()
        ProgressViewComponent.register()
    }
}
