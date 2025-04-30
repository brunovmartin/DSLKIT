import SwiftUI

public struct PickerView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        let labelText = DSLExpression.shared.evaluate(node["label"], context) as? String ?? ""
        let options = node["options"] as? [Any] ?? []
        
        // --- Binding --- 
        guard let varName = node["var"] as? String else {
            print("⚠️ PickerView: Parâmetro \'var\' (String) faltando na raiz do nó.")
            return AnyView(Text("Picker Error: \'var\' missing"))
        }
        
        // O tipo do Binding dependerá do tipo das 'tags' nas opções.
        // Usaremos String como padrão por enquanto, mas isso precisará ser mais flexível.
        // Idealmente, o tipo seria inferido ou especificado.
        let selectionBinding: Binding<String> = BindingResolver.bind(
            varName, 
            context: context, 
            defaultValue: "", // Valor padrão se a variável não existir
            onChangeAction: node["onChange"] // Passa a ação onChange, se houver
        )
        
        print("--- DEBUG: PickerView render - var: \(varName), current value: \(selectionBinding.wrappedValue)")

        // --- Criação do Picker --- 
        let picker = Picker(labelText, selection: selectionBinding) {
            // Iterar sobre as opções e renderizá-las
            ForEach(0..<options.count, id: \.self) { index in
                renderOption(options[index], context: context)
            }
        }

        var finalView = AnyView(picker)

        // --- Aplica Modificadores --- 
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }
        
        // Aplicar modificadores de ação diretamente do node
        finalView = applyActionModifiers(node: node, context: context, to: finalView)
        
        return finalView
    }

    // Função auxiliar para renderizar uma única opção
    @ViewBuilder
    private static func renderOption(_ optionData: Any, context: DSLContext) -> some View {
        if let optionString = optionData as? String {
            // Opção simples: string é tanto o texto quanto o valor (tag)
            Text(optionString).tag(optionString)
        } else if let optionDict = optionData as? [String: Any] {
            // Opção complexa: dicionário com 'tag' e 'content'
            let tagValue = DSLExpression.shared.evaluate(optionDict["tag"], context) as? String ?? ""
            let contentNode = optionDict["content"] as? [String: Any]
            
            if let content = contentNode {
                // Renderiza o conteúdo customizado
                DSLViewRenderer.renderComponent(from: content, context: context)
                    .tag(tagValue)
            } else {
                // Se 'content' não for um nó válido, usa a tag como texto
                Text(tagValue).tag(tagValue)
            }
        } else {
            // Caso inválido
            Text("Invalid Option").tag("INVALID_TAG_\(UUID())") // Tag única para evitar conflitos
        }
    }

    public static func register() {
        DSLComponentRegistry.shared.register("picker", builder: render)
        
        // Registra modificadores de base comuns
        registerBaseViewModifiers(on: modifierRegistry)
        
        // --- Modificadores Específicos do Picker ---
        modifierRegistry.register("pickerStyle") { view, value, context in
            let styleName = DSLExpression.shared.evaluate(value, context) as? String
            var styledView = view
            
            switch styleName?.lowercased() {
            case "menu":
                styledView = AnyView(view.pickerStyle(.menu))
            case "segmented":
                if #available(iOS 13.0, macOS 10.15, *) {
                   styledView = AnyView(view.pickerStyle(.segmented))
                } else {
                   print("⚠️ SegmentedPickerStyle não disponível nesta versão de OS.")
                }
            case "wheel":
                 if #available(iOS 13.0, macOS 11.0, *) { // macOS 11+ for wheel
                    styledView = AnyView(view.pickerStyle(.wheel))
                 } else {
                     print("⚠️ WheelPickerStyle não disponível nesta versão de OS.")
                 }
            case "inline":
                 if #available(iOS 14.0, macOS 11.0, *) {
                    styledView = AnyView(view.pickerStyle(.inline))
                 } else {
                     print("⚠️ InlinePickerStyle não disponível nesta versão de OS.")
                 }
            // Adicione outros estilos como .navigationLink se necessário
            default:
                styledView = AnyView(view.pickerStyle(.automatic))
            }
            return styledView
        }
        
        // Outros modificadores como 'disabled', 'tint' já estão nos base
    }
} 
