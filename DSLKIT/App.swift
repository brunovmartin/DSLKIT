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
                NavigationStack(path: $interpreter.navigationPath) {
                    Group {
                        if let rootScreen = interpreter.getRootScreenDefinition() {
                            DSLViewRenderer.renderScreenContent(screen: rootScreen, context: appContext)
                        } else {
                            Text("Erro: Tela raiz não definida após carregamento.")
                        }
                    }
                    .navigationDestination(for: String.self) { screenId in
                        if let screenDefinition = engine.getScreenDefinition(byId: screenId) {
                            DSLViewRenderer.renderScreenContent(screen: screenDefinition, context: appContext)
                        } else {
                            Text("🚫 Destino de navegação não encontrado para ID: \(screenId)")
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
                        RegistrySetup.registerAll()
                        engine.start(context: appContext)
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
                print("⚠️ Aviso: Alert com mais de 2 botões solicitado. Exibindo apenas os dois primeiros.")
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

