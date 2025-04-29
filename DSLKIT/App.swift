import SwiftUI

@main
struct DSLApp: App {
    @StateObject private var appContext = DSLContext(initial: [:])
    @StateObject private var interpreter = DSLInterpreter.shared
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
            } else {
                Color.clear
                    .onAppear {
                        RegistrySetup.registerAll()
                        engine.start(context: appContext)
                    }
            }
        }
    }
}

