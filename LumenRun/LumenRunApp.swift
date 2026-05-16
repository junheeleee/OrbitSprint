import SwiftUI

@main
struct LumenRunApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var gameCenter = GameCenterManager.shared

    init() {
        SoundPlayer.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .environmentObject(gameCenter)
                .task {
                    gameCenter.authenticate()
                }
        }
    }
}
