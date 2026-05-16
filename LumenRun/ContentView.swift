import SpriteKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var gameCenter: GameCenterManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: GameScene?
    @State private var didScheduleLoading = false
    @State private var isRecordsPresented = false

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
        .sheet(isPresented: $gameCenter.isShowingLeaderboard) {
            GameCenterLeaderboardView()
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isRecordsPresented) {
            RecordsView()
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
                } showRecords: {
                    isRecordsPresented = true
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

            DailyMissionsPanel()

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
    @EnvironmentObject private var gameCenter: GameCenterManager
    let restart: () -> Void
    let showRecords: () -> Void

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
