import SwiftUI

@main
struct OrbitSprintApp: App {
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
