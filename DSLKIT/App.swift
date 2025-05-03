import SwiftUI

@main
struct DSLApp: App {
    @StateObject private var appContext = DSLContext(initial: [:])
    @StateObject private var interpreter = DSLInterpreter.shared
    @StateObject private var alertManager = AlertManager.shared
    let engine = DSLAppEngine.shared

    var body: some Scene {
        WindowGroup {
            if appContext.isInitialLoadComplete {
                Group {
                    if let tabDefs = engine.tabDefinitions {
                        TabView {
                            ForEach(0..<tabDefs.count, id: \.self) { index in
                                let tabDef = tabDefs[index]
                                if let screenId = tabDef["screenId"] as? String,
                                   let rootScreen = engine.getScreenDefinition(byId: screenId),
                                   let label = tabDef["label"] as? String {
                                    NavigationStack(path: $interpreter.navigationPath) {
                                        DSLViewRenderer.renderScreenContent(screen: rootScreen, context: appContext)
                                        .navigationDestination(for: String.self) { screenId in
                                            if let screenDefinition = engine.getScreenDefinition(byId: screenId) {
                                                DSLViewRenderer.renderScreenContent(screen: screenDefinition, context: appContext)
                                            } else {
                                                Text("🚫 Destino de navegação não encontrado para ID: \(screenId)")
                                            }
                                        }
                                    }
                                    .tabItem {
                                        if let iconName = tabDef["icon"] as? String { Image(systemName: iconName) }
                                        Text(label)
                                    }
                                    .tag(screenId)

                                } else {
                                    Text("Erro: Definição de Tab inválida [\(index)] (ID: \(tabDef["screenId"] ?? "?"))")
                                        .tabItem { Label("Erro", systemImage: "exclamationmark.triangle") }
                                        .tag(UUID())
                                }
                            }
                        }
                    } else {
                        if let rootScreen = interpreter.getRootScreenDefinition() {
                            NavigationStack(path: $interpreter.navigationPath) {
                                DSLViewRenderer.renderScreenContent(screen: rootScreen, context: appContext)
                                .navigationDestination(for: String.self) { screenId in
                                    if let screenDefinition = engine.getScreenDefinition(byId: screenId) {
                                        DSLViewRenderer.renderScreenContent(screen: screenDefinition, context: appContext)
                                    } else {
                                        Text("🚫 Destino de navegação não encontrado para ID: \(screenId)")
                                    }
                                }
                            }
                        } else {
                            Text("Erro Fatal: Não foi possível obter a tela raiz do Interpreter (mainScreen: \(engine.initialScreenId ?? "N/A"))")
                                 .foregroundColor(.red)
                                 .padding()
                        }
                    }
                }
                .environmentObject(appContext)
                .environment(\.colorScheme, (appContext.get("environmentColorScheme") as? String ?? "light") == "dark" ? .dark : .light)
                .alert(item: $alertManager.alertItem) { item in
                    createAlert(from: item)
                }
            } else {
                Color.clear
                    .onAppear {
                        if !appContext.isInitialLoadComplete {
                            logDebug("--- App.onAppear: Loading initial state...")
                            RegistrySetup.registerAll()
                            engine.start(context: appContext, interpreter: interpreter)
                        }
                    }
             }
        }
    }
    
    private func createAlert(from item: AlertItem) -> Alert {
        let btns = item.buttons

        if btns.isEmpty {
            return Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
        } else if btns.count == 1 {
            return Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: mapButton(btns[0])
            )
        } else {
            if btns.count > 2 {
                logDebug("⚠️ Aviso: Alert com mais de 2 botões solicitado. Exibindo apenas os dois primeiros.")
            }
            return Alert(
                title: Text(item.title),
                message: Text(item.message),
                primaryButton: mapButton(btns[0]),
                secondaryButton: mapButton(btns[1])
            )
        }
    }

    private func mapButton(_ btn: AlertButton) -> Alert.Button {
        let actionClosure: (() -> Void)? = {
            if let actionCommand = btn.action {
                DSLInterpreter.shared.handleEvent(actionCommand, context: appContext)
            }
        }

        switch btn.role {
        case .cancel:
            return .cancel(Text(btn.label), action: actionClosure)
        case .destructive:
            return .destructive(Text(btn.label), action: actionClosure)
        default:
            return .default(Text(btn.label), action: actionClosure)
        }
    }
}
