import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: GameScene?
    @State private var didScheduleLoading = false

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }

            if gameState.isFeverActive {
                FeverBackdrop()
                    .transition(.opacity)
            }

            gameOverlay

            if gameState.isLoading {
                LoadingView()
                    .transition(.opacity)
            } else if gameState.isStartScreenPresented {
                StartView {
                    gameState.startRun()
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(
            LinearGradient(
                colors: gameState.selectedTheme.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $gameState.isSettingsPresented) {
            SettingsView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if scene == nil {
                scene = makeScene()
            }
            SoundPlayer.setMusicEnabled(gameState.isSoundEnabled)
            scheduleLoadingFinish()
        }
        .onChange(of: scenePhase) { _, newPhase in
            gameState.setSceneActive(newPhase == .active)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isGameOver)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isUserPaused)
        .animation(.easeInOut(duration: 0.22), value: gameState.isFeverActive)
    }

    private func makeScene() -> GameScene {
        let scene = GameScene(state: gameState)
        scene.scaleMode = .resizeFill
        return scene
    }

    private var gameOverlay: some View {
        VStack(spacing: 0) {
            if !gameState.isLoading, !gameState.isStartScreenPresented {
                HUDView(
                    openSettings: {
                    gameState.pauseForSettings()
                    },
                    togglePause: {
                        gameState.togglePause()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }

            Spacer()

            if !gameState.hasSeenTutorial, !gameState.isStartScreenPresented, !gameState.isLoading {
                TutorialView {
                    gameState.completeTutorial()
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }

            if gameState.isGameOver {
                GameOverView {
                    gameState.reset()
                    scene = makeScene()
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }

            if gameState.isUserPaused, gameState.hasSeenTutorial, !gameState.isGameOver {
                PauseView {
                    gameState.resume()
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func scheduleLoadingFinish() {
        guard !didScheduleLoading else { return }
        didScheduleLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            gameState.finishLoading()
        }
    }
}

private struct HUDView: View {
    @EnvironmentObject private var gameState: GameState
    let openSettings: () -> Void
    let togglePause: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("app.title")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                Text("\(gameState.score)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                HStack(spacing: 8) {
                    StatusPill(text: String(format: NSLocalizedString("hud.level", comment: ""), gameState.level))
                    if gameState.multiplier > 1 {
                        StatusPill(text: "x\(gameState.multiplier)")
                    }
                }
            }

            Spacer()

            HStack(spacing: 14) {
                VStack(alignment: .trailing, spacing: 4) {
                    if gameState.combo > 0 {
                        VStack(alignment: .trailing, spacing: 3) {
                            if gameState.isFeverActive {
                                Text("hud.fever")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: gameState.selectedTheme.feverColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                            }

                            Text(String(format: NSLocalizedString("hud.combo", comment: ""), gameState.combo))
                                .font(.caption.weight(.black))
                                .foregroundStyle(gameState.isFeverActive ? .white : Color(red: 1.0, green: 0.82, blue: 0.28))
                                .monospacedDigit()
                        }
                    }
                    HStack(spacing: 5) {
                        if gameState.shieldCharges > 0 {
                            Label("\(gameState.shieldCharges)", systemImage: "shield.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.45, green: 0.82, blue: 1.0))
                        }
                        if gameState.slowTimeRemaining > 0 {
                            Label("\(Int(ceil(gameState.slowTimeRemaining)))", systemImage: "timer")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.76, green: 0.58, blue: 1.0))
                        }
                    }
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("hud.best")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                    Text("\(gameState.bestScore)")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
                        .monospacedDigit()
                }

                Button(action: togglePause) {
                    Image(systemName: gameState.isUserPaused ? "play.fill" : "pause.fill")
                        .font(.title3.weight(.bold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12), in: Circle())
                .disabled(!gameState.hasSeenTutorial || gameState.isGameOver)
                .accessibilityLabel(Text(gameState.isUserPaused ? "pause.resume" : "pause.title"))

                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3.weight(.bold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12), in: Circle())
                .accessibilityLabel(Text("settings.title"))
            }
        }
    }
}

private struct PauseView: View {
    @EnvironmentObject private var gameState: GameState
    let resume: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("pause.title")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Button(action: resume) {
                Label("pause.resume", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct LoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(.cyan, .pink)
                    .symbolEffect(.pulse)

                Text("loading.title")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
            }
        }
    }
}

private struct StartView: View {
    @EnvironmentObject private var gameState: GameState
    let start: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("start.eyebrow")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))
                    .tracking(1.8)

                Text("app.title")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gameState.selectedTheme.feverColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("start.subtitle")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                TutorialRow(icon: "hand.tap.fill", text: "tutorial.step.tap")
                TutorialRow(icon: "sparkles", text: "tutorial.step.collect")
                TutorialRow(icon: "flame.fill", text: "tutorial.step.fever")
            }

            Button(action: start) {
                Label("start.play", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct FeverBackdrop: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        LinearGradient(
            colors: gameState.selectedTheme.feverColors.map { $0.opacity(0.24) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct StatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.16), in: Capsule())
            .monospacedDigit()
    }
}

private struct TutorialView: View {
    @EnvironmentObject private var gameState: GameState
    let start: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("tutorial.title")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("tutorial.body")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                TutorialRow(icon: "hand.tap.fill", text: "tutorial.step.tap")
                TutorialRow(icon: "sparkles", text: "tutorial.step.collect")
                TutorialRow(icon: "exclamationmark.triangle.fill", text: "tutorial.step.avoid")
                TutorialRow(icon: "bolt.shield.fill", text: "tutorial.step.powerups")
            }

            Button(action: start) {
                Label("tutorial.start", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TutorialRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 26)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
        }
    }
}

private struct GameOverView: View {
    @EnvironmentObject private var gameState: GameState
    let restart: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("gameover.title")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(String(format: NSLocalizedString("gameover.score", comment: ""), gameState.score, gameState.bestScore))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .monospacedDigit()

                Text(String(format: NSLocalizedString("gameover.level", comment: ""), gameState.level))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .monospacedDigit()
            }

            Button(action: restart) {
                Label("gameover.restart", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(gameState.selectedTheme.accentColor)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.play") {
                    Toggle("settings.sound", isOn: $gameState.isSoundEnabled)
                    Toggle("settings.haptics", isOn: $gameState.isHapticsEnabled)
                }

                Section("settings.theme") {
                    Picker("settings.theme", selection: $gameState.selectedTheme) {
                        ForEach(GameTheme.allCases) { theme in
                            Text(theme.titleKey).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings.record") {
                    HStack {
                        Text("hud.best")
                        Spacer()
                        Text("\(gameState.bestScore)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    Button("settings.resetBest", role: .destructive) {
                        gameState.resetBestScore()
                    }
                }

                Section("settings.help") {
                    Button("settings.showTutorial") {
                        gameState.showTutorialAgain()
                    }
                }
            }
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        gameState.closeSettings()
                    }
                }
            }
        }
    }
}
