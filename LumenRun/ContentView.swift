import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: GameScene?
    @State private var didScheduleLoading = false
    @State private var isRecordsPresented = false
    @State private var isObjectGuidePresented = false

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

            achievementToastOverlay

            if gameState.isLoading {
                LoadingView()
                    .transition(.opacity)
            } else if gameState.isStartScreenPresented {
                ScrollView(.vertical, showsIndicators: true) {
                    StartView {
                        gameState.startRun()
                    } showRewards: {
                        gameState.showRewards()
                    } showObjectGuide: {
                        isObjectGuidePresented = true
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameState.isAchievementsPresented) {
            AchievementsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameState.isRewardsPresented) {
            RewardsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $gameCenter.isShowingLeaderboard) {
            GameCenterLeaderboardView()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isRecordsPresented) {
            RecordsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isObjectGuidePresented) {
            ObjectGuideView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if scene == nil {
                scene = makeScene()
            }
            gameState.refreshDailyMissionsIfNeeded()
            SoundPlayer.setMusicEnabled(gameState.isSoundEnabled)
            scheduleLoadingFinish()
        }
        .onChange(of: scenePhase) { _, newPhase in
            gameState.setSceneActive(newPhase == .active)
        }
        .onChange(of: gameState.achievementToast?.id) { _, _ in
            scheduleAchievementToastDismiss()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isGameOver)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.isUserPaused)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: gameState.achievementToast?.id)
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
                    openAchievements: {
                        gameState.showAchievements()
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
                ScrollView(.vertical, showsIndicators: true) {
                    GameOverView {
                        gameState.reset()
                        scene = makeScene()
                    } showRecords: {
                        isRecordsPresented = true
                    } showAchievements: {
                        gameState.showAchievements()
                    } showRewards: {
                        gameState.showRewards()
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
            }

            if gameState.isUserPaused, gameState.hasSeenTutorial, !gameState.isGameOver {
                PauseView {
                    gameState.resume()
                } showObjectGuide: {
                    isObjectGuidePresented = true
                }
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var achievementToastOverlay: some View {
        if let achievement = gameState.achievementToast {
            VStack {
                AchievementToastView(achievement: achievement)
                    .padding(.horizontal, 20)
                    .padding(.top, 64)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(8)
            .allowsHitTesting(false)
        }
    }

    private func scheduleLoadingFinish() {
        guard !didScheduleLoading else { return }
        didScheduleLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            gameState.finishLoading()
        }
    }

    private func scheduleAchievementToastDismiss() {
        guard let achievement = gameState.achievementToast else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            gameState.dismissAchievementToast(achievement)
        }
    }
}

private struct AchievementToastView: View {
    let achievement: AchievementDefinition

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.28).opacity(0.22))

                Image(systemName: achievement.iconName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.34))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text("achievements.toast")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.34))
                    .textCase(.uppercase)

                Text(LocalizedStringKey(achievement.titleKey))
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.86, blue: 0.34).opacity(0.9),
                            Color(red: 0.0, green: 0.92, blue: 0.82).opacity(0.55)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.18).opacity(0.25), radius: 18, x: 0, y: 10)
    }
}

private struct HUDView: View {
    @EnvironmentObject private var gameState: GameState
    let openSettings: () -> Void
    let openAchievements: () -> Void
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

            HStack(spacing: 9) {
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
                        if gameState.shieldTimeRemaining > 0 {
                            Label("\(Int(ceil(gameState.shieldTimeRemaining)))", systemImage: "shield.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.45, green: 0.82, blue: 1.0))
                        }
                        if gameState.slowTimeRemaining > 0 {
                            Label("\(Int(ceil(gameState.slowTimeRemaining)))", systemImage: "timer")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.76, green: 0.58, blue: 1.0))
                        }
                        if gameState.magnetTimeRemaining > 0 {
                            Label("\(Int(ceil(gameState.magnetTimeRemaining)))", systemImage: "dot.radiowaves.left.and.right")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.24, green: 0.92, blue: 0.84))
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
                        .font(.headline.weight(.bold))
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12), in: Circle())
                .contentShape(Circle())
                .disabled(!gameState.hasSeenTutorial || gameState.isGameOver)
                .accessibilityLabel(Text(gameState.isUserPaused ? "pause.resume" : "pause.title"))

                Button(action: openAchievements) {
                    Image(systemName: "trophy.fill")
                        .font(.headline.weight(.bold))
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
                .background(.white.opacity(0.12), in: Circle())
                .contentShape(Circle())
                .accessibilityLabel(Text("achievements.title"))

                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.headline.weight(.bold))
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12), in: Circle())
                .contentShape(Circle())
                .accessibilityLabel(Text("settings.title"))
            }
        }
    }
}

private struct PauseView: View {
    @EnvironmentObject private var gameState: GameState
    let resume: () -> Void
    let showObjectGuide: () -> Void

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

            Button(action: showObjectGuide) {
                Label("objects.title", systemImage: "questionmark.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)
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
    let showRewards: () -> Void
    let showObjectGuide: () -> Void

    var body: some View {
        VStack(spacing: 18) {
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

            DailyMissionsPanel()

            Button(action: showRewards) {
                Label("rewards.title", systemImage: "gift.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: showObjectGuide) {
                Label("objects.title", systemImage: "questionmark.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 26)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GameOverView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager
    let restart: () -> Void
    let showRecords: () -> Void
    let showAchievements: () -> Void
    let showRewards: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                if gameState.didSetNewBestThisRun {
                    Label("gameover.newBest", systemImage: "crown.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.86, blue: 0.24), Color(red: 1.0, green: 0.52, blue: 0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }

                Text("gameover.title")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(gameState.score)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text(resultSubtitle)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(gameState.didSetNewBestThisRun ? Color(red: 1.0, green: 0.82, blue: 0.28) : .white.opacity(0.66))
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ResultStatCard(title: "hud.best", value: "\(gameState.bestScore)", icon: "trophy.fill")
                    ResultStatCard(
                        title: "gameover.level.short",
                        value: "\(gameState.level)",
                        icon: "speedometer"
                    )
                }
                HStack(spacing: 8) {
                    ResultStatCard(
                        title: "gameover.missions.short",
                        value: "\(gameState.completedDailyMissionTotal)/\(gameState.dailyMissions.count)",
                        icon: "target"
                    )
                    ResultStatCard(
                        title: "rewards.completedMissions",
                        value: "\(gameState.completedMissionCount)",
                        icon: "checkmark.seal.fill"
                    )
                }
                HStack(spacing: 8) {
                    ResultStatCard(
                        title: "achievements.title",
                        value: "\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)",
                        icon: "medal.fill"
                    )
                }
            }

            if let unlockText {
                Label(unlockText, systemImage: "lock.open.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if gameCenter.lastSubmissionSucceeded {
                Label("gamecenter.submitted", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.52, green: 1.0, blue: 0.72))
            } else if gameCenter.lastSubmissionError != nil {
                Label("gamecenter.submitFailed", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.32))
            }

            DailyMissionsPanel(isCompact: true)

            Button(action: showRecords) {
                Label("records.title", systemImage: "chart.bar.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: showAchievements) {
                Label("achievements.title", systemImage: "trophy.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button(action: showRewards) {
                Label("rewards.title", systemImage: "gift.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button {
                gameCenter.showLeaderboard()
            } label: {
                Label("gamecenter.leaderboard", systemImage: "list.number")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.white)

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

    private var resultSubtitle: String {
        if gameState.didSetNewBestThisRun {
            return NSLocalizedString("gameover.newBest.subtitle", comment: "")
        }
        if gameState.bestScoreDelta >= 0 {
            return NSLocalizedString("gameover.tiedBest", comment: "")
        }
        return String(format: NSLocalizedString("gameover.bestDelta", comment: ""), abs(gameState.bestScoreDelta))
    }

    private var unlockText: String? {
        guard let nextTheme = gameState.nextLockedTheme, let remaining = gameState.missionsUntilNextTheme else {
            return NSLocalizedString("gameover.allThemesUnlocked", comment: "")
        }
        return String(
            format: NSLocalizedString("gameover.nextTheme", comment: ""),
            remaining,
            NSLocalizedString(nextTheme.titleLocalizationKey, comment: "")
        )
    }
}

private struct ResultStatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.play") {
                    Toggle("settings.sound", isOn: $gameState.isSoundEnabled)
                    Toggle("settings.haptics", isOn: $gameState.isHapticsEnabled)
                }

                Section("settings.theme") {
                    ForEach(GameTheme.allCases) { theme in
                        ThemeUnlockRow(theme: theme)
                    }
                    HStack {
                        Text("rewards.completedMissions")
                        Spacer()
                        Text("\(gameState.completedMissionCount)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                Section("settings.theme.quick") {
                    Picker("settings.theme", selection: $gameState.selectedTheme) {
                        ForEach(GameTheme.allCases) { theme in
                            Text(theme.titleKey)
                                .tag(theme)
                                .disabled(!gameState.isThemeUnlocked(theme))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings.skin") {
                    ForEach(CoreSkin.allCases) { skin in
                        CoreSkinUnlockRow(skin: skin)
                    }
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
                    Button("records.reset", role: .destructive) {
                        gameState.resetRunRecords()
                    }
                }

                Section("missions.title") {
                    ForEach(gameState.dailyMissions) { mission in
                        MissionRow(mission: mission)
                    }
                }

                Section("achievements.title") {
                    HStack {
                        Text("achievements.all")
                        Spacer()
                        Text("\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    ForEach(AchievementDefinition.all) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }

                Section("gamecenter.title") {
                    HStack {
                        Text("gamecenter.status")
                        Spacer()
                        Text(gameCenter.isAuthenticated ? gameCenter.playerAlias : NSLocalizedString("gamecenter.notConnected", comment: ""))
                            .fontWeight(.semibold)
                            .foregroundStyle(gameCenter.isAuthenticated ? .primary : .secondary)
                    }

                    Button {
                        gameState.closeSettings()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            gameCenter.showLeaderboard()
                        }
                    } label: {
                        Label("gamecenter.leaderboard", systemImage: "list.number")
                    }
                }

                Section("settings.help") {
                    Button("settings.showTutorial") {
                        gameState.showTutorialAgain()
                    }
                    NavigationLink {
                        ObjectGuideList()
                            .navigationTitle("objects.title")
                    } label: {
                        Label("objects.title", systemImage: "questionmark.circle.fill")
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

private struct ObjectGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ObjectGuideList()
                .navigationTitle("objects.title")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("settings.done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct ObjectGuideList: View {
    private let items = LumenObjectKind.allCases

    var body: some View {
        List {
            Section {
                Text("objects.subtitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("objects.title") {
                ForEach(items) { item in
                    ObjectGuideRow(item: item)
                }
            }
        }
    }
}

private struct ObjectGuideRow: View {
    let item: LumenObjectKind

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.guideColor.opacity(0.16))
                ObjectGuideIcon(kind: item, color: item.guideColor)
                    .frame(width: 32, height: 32)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 5) {
                Text(LocalizedStringKey(item.titleKey))
                    .font(.headline.weight(.bold))
                Text(LocalizedStringKey(item.descriptionKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ObjectGuideIcon: View {
    let kind: LumenObjectKind
    let color: Color

    var body: some View {
        ZStack {
            baseObject

            switch kind {
            case .spark:
                Circle()
                    .fill(.white.opacity(0.78))
                    .frame(width: 7, height: 7)
            case .surge:
                LightningGuideShape()
                    .fill(.white.opacity(0.9))
                    .frame(width: 18, height: 22)
            case .shield:
                CheckGuideShape()
                    .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 3.1, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 20)
            case .slow:
                VStack(spacing: 6) {
                    Capsule().fill(.white.opacity(0.86)).frame(width: 9, height: 5)
                    Capsule().fill(.white.opacity(0.86)).frame(width: 9, height: 5)
                }
            case .magnet:
                PullArrowGuideShape()
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
            case .bomb:
                ClearSlashGuideShape()
                    .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 3.1, lineCap: .round))
                    .frame(width: 22, height: 22)
            case .shard:
                XGuideShape()
                    .stroke(.black.opacity(0.66), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                    .frame(width: 21, height: 21)
            }
        }
    }

    @ViewBuilder
    private var baseObject: some View {
        switch kind {
        case .spark:
            StarGuideShape(points: 5, innerRatio: 0.42)
                .fill(color)
                .overlay(StarGuideShape(points: 5, innerRatio: 0.42).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .surge:
            PolygonGuideShape(sides: 6, rotation: .pi / 6)
                .fill(color)
                .overlay(PolygonGuideShape(sides: 6, rotation: .pi / 6).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .shield:
            ShieldGuideShape()
                .fill(color)
                .overlay(ShieldGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .slow:
            HourglassGuideShape()
                .fill(color)
                .overlay(HourglassGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .magnet:
            MagnetBodyGuideShape()
                .fill(color)
                .overlay(MagnetBodyGuideShape().stroke(color.opacity(0.95), lineWidth: 1.4))
        case .bomb:
            BurstGuideShape(points: 8, innerRatio: 0.46)
                .fill(color)
                .overlay(BurstGuideShape(points: 8, innerRatio: 0.46).stroke(color.opacity(0.95), lineWidth: 1.4))
        case .shard:
            StarGuideShape(points: 6, innerRatio: 0.58)
                .fill(color)
                .overlay(StarGuideShape(points: 6, innerRatio: 0.58).stroke(color.opacity(0.95), lineWidth: 1.4))
        }
    }
}

private struct StarGuideShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) * 0.47
        let inner = outer * innerRatio

        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct BurstGuideShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        StarGuideShape(points: points, innerRatio: innerRatio).path(in: rect)
    }
}

private struct MagnetBodyGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: rect.minX + width * 0.06, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.36, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.36, y: rect.minY + height * 0.58))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.64, y: rect.minY + height * 0.58),
            control: CGPoint(x: rect.midX, y: rect.minY + height * 0.88)
        )
        path.addLine(to: CGPoint(x: rect.minX + width * 0.64, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.94, y: rect.minY + height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.94, y: rect.minY + height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.06, y: rect.minY + height * 0.6),
            control: CGPoint(x: rect.midX, y: rect.minY + height * 1.12)
        )
        path.closeSubpath()
        return path
    }
}

private struct PullArrowGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.midY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.7))
        return path
    }
}

private struct ClearSlashGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.22))
        return path
    }
}

private struct PolygonGuideShape: Shape {
    let sides: Int
    let rotation: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.45

        for index in 0..<sides {
            let angle = CGFloat(index) / CGFloat(sides) * 2 * .pi + rotation
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

private struct ShieldGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.42
        let top = center.y - radius * 0.75
        let shoulder = center.y - radius * 0.1
        let tip = center.y + radius * 1.15

        path.move(to: CGPoint(x: center.x - radius, y: top))
        path.addLine(to: CGPoint(x: center.x + radius, y: top))
        path.addLine(to: CGPoint(x: center.x + radius, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: tip),
            control: CGPoint(x: center.x + radius * 0.72, y: center.y + radius * 0.64)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - radius, y: shoulder),
            control: CGPoint(x: center.x - radius * 0.72, y: center.y + radius * 0.64)
        )
        path.closeSubpath()
        return path
    }
}

private struct HourglassGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.43
        let width = radius * 0.78
        let waist = radius * 0.18

        path.move(to: CGPoint(x: center.x - width, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + width, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y))
        path.addLine(to: CGPoint(x: center.x + width, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - width, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y))
        path.closeSubpath()
        return path
    }
}

private struct LightningGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x + size * 0.08, y: center.y - size * 0.5))
        path.addLine(to: CGPoint(x: center.x - size * 0.36, y: center.y - size * 0.05))
        path.addLine(to: CGPoint(x: center.x - size * 0.04, y: center.y - size * 0.05))
        path.addLine(to: CGPoint(x: center.x - size * 0.18, y: center.y + size * 0.5))
        path.addLine(to: CGPoint(x: center.x + size * 0.36, y: center.y - size * 0.08))
        path.addLine(to: CGPoint(x: center.x + size * 0.04, y: center.y - size * 0.08))
        path.closeSubpath()
        return path
    }
}

private struct CheckGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.2))
        return path
    }
}

private struct XGuideShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

private struct AchievementsView: View {
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("achievements.all")
                        Spacer()
                        Text("\(gameState.completedAchievementCount)/\(AchievementDefinition.all.count)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }

                Section("achievements.title") {
                    ForEach(AchievementDefinition.all) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
            .navigationTitle("achievements.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        gameState.closeAchievements()
                    }
                }
            }
        }
    }
}

private struct AchievementRow: View {
    @EnvironmentObject private var gameState: GameState
    let achievement: AchievementDefinition

    var body: some View {
        let progress = gameState.achievementProgress(for: achievement)
        let isUnlocked = gameState.isAchievementUnlocked(achievement)

        HStack(spacing: 12) {
            Image(systemName: isUnlocked ? "checkmark.seal.fill" : achievement.iconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(LocalizedStringKey(achievement.titleKey))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isUnlocked ? .primary : .secondary)
                    Spacer()
                    AchievementStatusBadge(isUnlocked: isUnlocked)
                }

                Text(LocalizedStringKey(achievement.descriptionKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(progress), total: Double(achievement.target))
                    .tint(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 0.0, green: 0.92, blue: 0.82))

                Text("\(progress)/\(achievement.target)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 3)
    }
}

private struct AchievementStatusBadge: View {
    let isUnlocked: Bool

    var body: some View {
        Label(
            isUnlocked ? "rewards.unlocked" : "achievements.locked",
            systemImage: isUnlocked ? "checkmark.seal.fill" : "lock.fill"
        )
        .font(.caption2.weight(.black))
        .labelStyle(.titleAndIcon)
        .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72).opacity(0.12) : Color.secondary.opacity(0.12))
        )
    }
}

private struct ThemeUnlockRow: View {
    @EnvironmentObject private var gameState: GameState
    let theme: GameTheme

    var body: some View {
        Button {
            guard gameState.isThemeUnlocked(theme) else { return }
            gameState.selectedTheme = theme
        } label: {
            HStack(spacing: 12) {
                LinearGradient(
                    colors: theme.feverColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.24), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.titleKey)
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: trailingIcon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(gameState.selectedTheme == theme ? gameState.selectedTheme.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!gameState.isThemeUnlocked(theme))
    }

    private var subtitle: String {
        if gameState.isThemeUnlocked(theme) {
            return NSLocalizedString("rewards.unlocked", comment: "")
        }
        return String(format: NSLocalizedString("rewards.unlockAt", comment: ""), theme.unlockRequirement)
    }

    private var trailingIcon: String {
        if gameState.selectedTheme == theme {
            return "checkmark.circle.fill"
        }
        return gameState.isThemeUnlocked(theme) ? "circle" : "lock.fill"
    }
}

private struct CoreSkinUnlockRow: View {
    @EnvironmentObject private var gameState: GameState
    let skin: CoreSkin

    var body: some View {
        Button {
            guard gameState.isCoreSkinUnlocked(skin) else { return }
            gameState.selectedCoreSkin = skin
        } label: {
            HStack(spacing: 12) {
                Image(systemName: skin.iconName)
                    .font(.title3.weight(.black))
                    .foregroundStyle(gameState.selectedTheme.accentColor)
                    .frame(width: 34, height: 34)
                    .background(.secondary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(skin.titleKey)
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: trailingIcon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(gameState.selectedCoreSkin == skin ? gameState.selectedTheme.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!gameState.isCoreSkinUnlocked(skin))
    }

    private var subtitle: String {
        if gameState.isCoreSkinUnlocked(skin) {
            return NSLocalizedString("rewards.unlocked", comment: "")
        }
        return String(format: NSLocalizedString("rewards.unlockAt", comment: ""), skin.unlockRequirement)
    }

    private var trailingIcon: String {
        if gameState.selectedCoreSkin == skin {
            return "checkmark.circle.fill"
        }
        return gameState.isCoreSkinUnlocked(skin) ? "circle" : "lock.fill"
    }
}

private struct RewardsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                RewardShowcasePanel()
                    .padding(20)
            }
            .navigationTitle(Text("rewards.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RewardShowcasePanel: View {
    @EnvironmentObject private var gameState: GameState
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("rewards.previewTitle", systemImage: "sparkles")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.28))
                Spacer()
                Text("\(gameState.completedMissionCount)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.72))
                    .monospacedDigit()
            }

            Text("rewards.previewSubtitle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))

            RewardCategoryRow(title: "settings.theme", icon: "paintpalette.fill") {
                ForEach(GameTheme.allCases) { theme in
                    let isUnlocked = gameState.isThemeUnlocked(theme)
                    let isSelected = gameState.selectedTheme == theme
                    RewardPreviewCard(
                        title: theme.titleKey,
                        subtitle: rewardSubtitle(required: theme.unlockRequirement, isUnlocked: isUnlocked, isSelected: isSelected),
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onSelect: {
                            if isUnlocked {
                                gameState.selectedTheme = theme
                            }
                        }
                    ) {
                        LinearGradient(
                            colors: theme.feverColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }

            RewardCategoryRow(title: "settings.skin", icon: "circle.hexagongrid.fill") {
                ForEach(CoreSkin.allCases) { skin in
                    let isUnlocked = gameState.isCoreSkinUnlocked(skin)
                    let isSelected = gameState.selectedCoreSkin == skin
                    RewardPreviewCard(
                        title: skin.titleKey,
                        subtitle: rewardSubtitle(required: skin.unlockRequirement, isUnlocked: isUnlocked, isSelected: isSelected),
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onSelect: {
                            if isUnlocked {
                                gameState.selectedCoreSkin = skin
                            }
                        }
                    ) {
                        ZStack {
                            Circle()
                                .fill(gameState.selectedTheme.accentColor.opacity(0.22))
                            Image(systemName: skin.iconName)
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(gameState.selectedTheme.accentColor)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func rewardSubtitle(required: Int, isUnlocked: Bool, isSelected: Bool) -> String {
        if isSelected {
            return NSLocalizedString("rewards.equipped", comment: "")
        }
        if isUnlocked {
            return NSLocalizedString("rewards.tapToEquip", comment: "")
        }
        let remaining = max(0, required - gameState.completedMissionCount)
        return String(format: NSLocalizedString("rewards.remaining", comment: ""), remaining)
    }
}

private struct RewardCategoryRow<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.76))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    content()
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct RewardPreviewCard<Preview: View>: View {
    let title: LocalizedStringKey
    let subtitle: String
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    preview()
                        .frame(width: 94, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .opacity(isUnlocked ? 1 : 0.52)

                    Image(systemName: isUnlocked ? (isSelected ? "checkmark.circle.fill" : "hand.tap.fill") : "lock.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : .white.opacity(0.78))
                        .padding(5)
                }

                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(subtitle)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isUnlocked ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 1.0, green: 0.82, blue: 0.28))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .padding(9)
        .frame(width: 112, height: 118, alignment: .topLeading)
        .background(.white.opacity(isSelected ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color(red: 0.52, green: 1.0, blue: 0.72).opacity(0.7) : .white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct DailyMissionsPanel: View {
    @EnvironmentObject private var gameState: GameState
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("missions.title", systemImage: "target")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 0.82))

            VStack(spacing: isCompact ? 7 : 9) {
                ForEach(gameState.dailyMissions) { mission in
                    MissionRow(mission: mission)
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MissionRow: View {
    let mission: DailyMission

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: mission.isCompleted ? "checkmark.seal.fill" : iconName)
                    .foregroundStyle(mission.isCompleted ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 1.0, green: 0.82, blue: 0.28))
                    .frame(width: 18)

                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                Text("\(mission.clampedProgress)/\(mission.target)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()
            }

            ProgressView(value: Double(mission.clampedProgress), total: Double(mission.target))
                .tint(mission.isCompleted ? Color(red: 0.52, green: 1.0, blue: 0.72) : Color(red: 0.0, green: 0.92, blue: 0.82))
                .scaleEffect(x: 1, y: 0.7, anchor: .center)
        }
    }

    private var title: String {
        switch mission.kind {
        case .score:
            return String(format: NSLocalizedString("missions.score", comment: ""), mission.target)
        case .sparks:
            return String(format: NSLocalizedString("missions.sparks", comment: ""), mission.target)
        case .fever:
            return String(format: NSLocalizedString("missions.fever", comment: ""), mission.target)
        case .shields:
            return String(format: NSLocalizedString("missions.shields", comment: ""), mission.target)
        }
    }

    private var iconName: String {
        switch mission.kind {
        case .score:
            return "flag.checkered"
        case .sparks:
            return "sparkles"
        case .fever:
            return "flame.fill"
        case .shields:
            return "shield.fill"
        }
    }
}

private struct RecordsView: View {
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("records.top") {
                    if gameState.topRunRecords.isEmpty {
                        Text("records.empty")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(gameState.topRunRecords.enumerated()), id: \.element.id) { index, record in
                            RunRecordRow(rank: index + 1, record: record)
                        }
                    }
                }

                Section("records.recent") {
                    if gameState.recentRunRecords.isEmpty {
                        Text("records.empty")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(gameState.recentRunRecords.enumerated()), id: \.element.id) { index, record in
                            RunRecordRow(rank: index + 1, record: record)
                        }
                    }
                }
            }
            .navigationTitle("records.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RunRecordRow: View {
    let rank: Int
    let record: RunRecord

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline.weight(.black))
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: NSLocalizedString("records.score", comment: ""), record.score))
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                Text(String(format: NSLocalizedString("gameover.level", comment: ""), record.level))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.date, style: .date)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
