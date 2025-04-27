import SwiftUI

@main
struct DSLApp: App {
    @State private var isReady = false
    @StateObject private var appContext = DSLContext(initial: [:])
    @StateObject private var interpreter = DSLInterpreter.shared
    let engine = DSLAppEngine.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady {
                    if let view = interpreter.currentView {
                        view
                    } else {
                        Text("🚫 Nenhuma tela carregada")
                    }
                } else {
                    Color.clear.opacity(0)
                    .onAppear {
                        Task {
                            RegistrySetup.registerAll()
                            engine.start(context: appContext)
                            isReady = true
                        }
                    }
                }
            }
        }
    }
}

