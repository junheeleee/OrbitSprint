import Foundation

final class GameState: ObservableObject {
    @Published var score = 0
    @Published var bestScore: Int
    @Published var combo = 0
    @Published var multiplier = 1
    @Published var level = 1
    @Published var shieldCharges = 0
    @Published var slowTimeRemaining: TimeInterval = 0
    @Published var isGameOver = false
    @Published var isPaused: Bool
    @Published var isUserPaused = false
    @Published var isSceneActive = true
    @Published var isSettingsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var hasSeenTutorial: Bool
    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey) }
    }
    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsEnabledKey) }
    }
    @Published var selectedTheme: GameTheme {
        didSet { UserDefaults.standard.set(selectedTheme.rawValue, forKey: selectedThemeKey) }
    }

    private let bestScoreKey = "bestScore"
    private let tutorialKey = "hasSeenTutorial"
    private let soundEnabledKey = "soundEnabled"
    private let hapticsEnabledKey = "hapticsEnabled"
    private let selectedThemeKey = "selectedTheme"

    init() {
        let defaults = UserDefaults.standard
        bestScore = defaults.integer(forKey: bestScoreKey)
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        isPaused = !defaults.bool(forKey: tutorialKey)
        isSoundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        isHapticsEnabled = defaults.object(forKey: hapticsEnabledKey) as? Bool ?? true
        selectedTheme = GameTheme(rawValue: defaults.string(forKey: selectedThemeKey) ?? "") ?? .aurora
    }

    func reset() {
        score = 0
        combo = 0
        multiplier = 1
        level = 1
        shieldCharges = 0
        slowTimeRemaining = 0
        isGameOver = false
        isUserPaused = false
        updatePauseState()
    }

    func collectSpark() {
        combo += 1
        multiplier = min(5, 1 + combo / 5)
        score += multiplier
        level = max(1, score / 15 + 1)
        SoundPlayer.collect(enabled: isSoundEnabled)
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
    }

    func breakCombo() {
        combo = 0
        multiplier = 1
    }

    func grantShield() {
        shieldCharges = min(3, shieldCharges + 1)
        SoundPlayer.collect(enabled: isSoundEnabled)
    }

    func consumeShield() -> Bool {
        guard shieldCharges > 0 else { return false }
        shieldCharges -= 1
        breakCombo()
        SoundPlayer.fail(enabled: isSoundEnabled)
        return true
    }

    func triggerSlowTime(duration: TimeInterval) {
        slowTimeRemaining = max(slowTimeRemaining, duration)
        SoundPlayer.collect(enabled: isSoundEnabled)
    }

    func tick(delta: TimeInterval) {
        guard slowTimeRemaining > 0 else { return }
        slowTimeRemaining = max(0, slowTimeRemaining - delta)
    }

    func endGame() {
        isGameOver = true
        updatePauseState()
        SoundPlayer.fail(enabled: isSoundEnabled)
    }

    func completeTutorial() {
        hasSeenTutorial = true
        UserDefaults.standard.set(true, forKey: tutorialKey)
        updatePauseState()
    }

    func pauseForSettings() {
        isSettingsPresented = true
    }

    func closeSettings() {
        isSettingsPresented = false
    }

    func togglePause() {
        guard hasSeenTutorial, !isGameOver else { return }
        isUserPaused.toggle()
        updatePauseState()
    }

    func resume() {
        isUserPaused = false
        updatePauseState()
    }

    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        updatePauseState()
    }

    func showTutorialAgain() {
        isSettingsPresented = false
        hasSeenTutorial = false
        isUserPaused = false
        UserDefaults.standard.set(false, forKey: tutorialKey)
        updatePauseState()
    }

    func resetBestScore() {
        bestScore = 0
        UserDefaults.standard.set(0, forKey: bestScoreKey)
    }

    private func updatePauseState() {
        isPaused = !hasSeenTutorial || isGameOver || isSettingsPresented || isUserPaused || !isSceneActive
    }
}
