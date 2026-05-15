import SwiftUI

@main
struct LumenRunApp: App {
    @StateObject private var gameState = GameState()

    init() {
        SoundPlayer.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
        }
    }
}
