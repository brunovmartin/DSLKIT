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
                    SplashView() 
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

struct SplashView: View {
    var body: some View {
        VStack {
            Image(systemName: "sparkles")
                .resizable()
                .frame(width: 100, height: 100)
            Text("Bem-vindo!")
                .font(.largeTitle)
                .padding()
        }
    }
}
