import Foundation

struct RunRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let score: Int
    let level: Int
    let date: Date
}

enum MissionKind: String, Codable, CaseIterable {
    case score
    case sparks
    case fever
    case shields
}

struct DailyMission: Codable, Identifiable, Equatable {
    let id: String
    let kind: MissionKind
    let target: Int
    var progress: Int

    var isCompleted: Bool {
        progress >= target
    }

    var clampedProgress: Int {
        min(progress, target)
    }
}

final class GameState: ObservableObject {
    @Published var score = 0
    @Published var bestScore: Int
    @Published private(set) var runRecords: [RunRecord]
    @Published private(set) var dailyMissions: [DailyMission]
    @Published var combo = 0
    @Published var multiplier = 1
    @Published var level = 1
    @Published var shieldCharges = 0
    @Published var shieldTimeRemaining: TimeInterval = 0
    @Published var slowTimeRemaining: TimeInterval = 0
    @Published var feverRemaining: TimeInterval = 0
    @Published var isLoading = true {
        didSet { updatePauseState() }
    }
    @Published var isStartScreenPresented = true {
        didSet { updatePauseState() }
    }
    @Published var isGameOver = false
    @Published var isPaused: Bool
    @Published var isUserPaused = false
    @Published var isSceneActive = true
    @Published var isSettingsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var hasSeenTutorial: Bool
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
            SoundPlayer.setMusicEnabled(isSoundEnabled)
            SoundPlayer.setFeverActive(isFeverActive, enabled: isSoundEnabled)
        }
    }
    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsEnabledKey) }
    }
    @Published private(set) var completedMissionCount: Int
    @Published var selectedTheme: GameTheme {
        didSet {
            if !isThemeUnlocked(selectedTheme) {
                selectedTheme = .aurora
                return
            }
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: selectedThemeKey)
        }
    }

    private let bestScoreKey = "bestScore"
    private let runRecordsKey = "runRecords"
    private let dailyMissionsKey = "dailyMissions"
    private let dailyMissionsDateKey = "dailyMissionsDate"
    private let completedMissionCountKey = "completedMissionCount"
    private let rewardedMissionIDsKey = "rewardedMissionIDs"
    private let tutorialKey = "hasSeenTutorial"
    private let soundEnabledKey = "soundEnabled"
    private let hapticsEnabledKey = "hapticsEnabled"
    private let selectedThemeKey = "selectedTheme"
    private let feverComboThreshold = 12
    private let feverDuration: TimeInterval = 5
    private let shieldDuration: TimeInterval = 8
    private let shieldExtensionDuration: TimeInterval = 6

    var isFeverActive: Bool {
        feverRemaining > 0
    }

    var topRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.score > $1.score }.prefix(5))
    }

    var recentRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.date > $1.date }.prefix(5))
    }

    init() {
        let defaults = UserDefaults.standard
        bestScore = defaults.integer(forKey: bestScoreKey)
        runRecords = Self.loadRunRecords(from: defaults, key: runRecordsKey)
        dailyMissions = Self.loadDailyMissions(from: defaults, missionsKey: dailyMissionsKey, dateKey: dailyMissionsDateKey)
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        isPaused = true
        isSoundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        isHapticsEnabled = defaults.object(forKey: hapticsEnabledKey) as? Bool ?? true
        completedMissionCount = defaults.integer(forKey: completedMissionCountKey)
        selectedTheme = GameTheme(rawValue: defaults.string(forKey: selectedThemeKey) ?? "") ?? .aurora
        if selectedTheme.unlockRequirement > completedMissionCount {
            selectedTheme = .aurora
        }
        updateMissionRewards()
    }

    func reset() {
        score = 0
        combo = 0
        multiplier = 1
        level = 1
        shieldCharges = 0
        shieldTimeRemaining = 0
        slowTimeRemaining = 0
        feverRemaining = 0
        SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
        isGameOver = false
        isUserPaused = false
        isStartScreenPresented = false
        updatePauseState()
    }

    func finishLoading() {
        isLoading = false
    }

    func startRun() {
        hasSeenTutorial = true
        UserDefaults.standard.set(true, forKey: tutorialKey)
        isStartScreenPresented = false
        isUserPaused = false
        isGameOver = false
        updatePauseState()
    }

    func collectSpark() {
        if !isFeverActive {
            combo += 1
            if combo >= feverComboThreshold {
                combo = 0
                feverRemaining = feverDuration
                advanceMission(.fever, by: 1)
                SoundPlayer.feverStart(enabled: isSoundEnabled)
                SoundPlayer.setFeverActive(true, enabled: isSoundEnabled)
            }
        }

        multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
        score += multiplier + (isFeverActive ? 1 : 0)
        level = max(1, score / 15 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        advanceMission(.sparks, by: 1)
        updateScoreMission()
        updateBestScore()
    }

    func collectFeverHit() {
        guard isFeverActive else { return }
        score += max(3, multiplier + 2)
        level = max(1, score / 15 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateBestScore()
    }

    func breakCombo() {
        combo = 0
        multiplier = 1
        if isFeverActive {
            feverRemaining = 0
            SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
        }
    }

    func grantShield() {
        if shieldTimeRemaining > 0 {
            // 실드 발동 중 - 시간 연장
            shieldTimeRemaining = min(shieldTimeRemaining + shieldExtensionDuration, shieldDuration * 2)
        } else {
            // 새 실드 발동
            shieldCharges = 1
            shieldTimeRemaining = shieldDuration
        }
        SoundPlayer.shield(enabled: isSoundEnabled)
        advanceMission(.shields, by: 1)
    }

    func consumeShield() -> Bool {
        guard shieldTimeRemaining > 0 else { return false }
        shieldTimeRemaining = 0
        shieldCharges = 0
        breakCombo()
        SoundPlayer.shieldBreak(enabled: isSoundEnabled)
        return true
    }

    func triggerSlowTime(duration: TimeInterval) {
        slowTimeRemaining = max(slowTimeRemaining, duration)
        SoundPlayer.timeCore(enabled: isSoundEnabled)
    }

    func tick(delta: TimeInterval) {
        if shieldTimeRemaining > 0 {
            shieldTimeRemaining = max(0, shieldTimeRemaining - delta)
            if shieldTimeRemaining == 0 {
                shieldCharges = 0
            }
        }

        if slowTimeRemaining > 0 {
            slowTimeRemaining = max(0, slowTimeRemaining - delta)
        }

        if feverRemaining > 0 {
            feverRemaining = max(0, feverRemaining - delta)
            if feverRemaining == 0 {
                SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
            }
        }
    }

    func endGame() {
        guard !isGameOver else { return }
        isGameOver = true
        let finalScore = score
        feverRemaining = 0
        updateScoreMission()
        recordRun(score: finalScore, level: level)
        updatePauseState()
        SoundPlayer.crash(enabled: isSoundEnabled)
        SoundPlayer.setFeverActive(false, enabled: isSoundEnabled)
        Task { @MainActor in
            GameCenterManager.shared.submit(score: finalScore)
        }
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
        isStartScreenPresented = true
        hasSeenTutorial = false
        isUserPaused = false
        UserDefaults.standard.set(false, forKey: tutorialKey)
        updatePauseState()
    }

    func resetBestScore() {
        bestScore = 0
        UserDefaults.standard.set(0, forKey: bestScoreKey)
    }

    func resetRunRecords() {
        runRecords = []
        UserDefaults.standard.removeObject(forKey: runRecordsKey)
    }

    func isThemeUnlocked(_ theme: GameTheme) -> Bool {
        completedMissionCount >= theme.unlockRequirement
    }

    func refreshDailyMissionsIfNeeded() {
        let defaults = UserDefaults.standard
        let today = Self.todayKey()
        if defaults.string(forKey: dailyMissionsDateKey) != today {
            dailyMissions = Self.generateDailyMissions(for: today)
            saveDailyMissions()
        }
    }

    private func recordRun(score: Int, level: Int) {
        guard score > 0 else { return }
        let record = RunRecord(id: UUID(), score: score, level: level, date: Date())
        runRecords.insert(record, at: 0)
        runRecords = Array(runRecords.prefix(30))
        saveRunRecords()
    }

    private func updateBestScore() {
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
    }

    private func saveRunRecords() {
        guard let data = try? JSONEncoder().encode(runRecords) else { return }
        UserDefaults.standard.set(data, forKey: runRecordsKey)
    }

    private func advanceMission(_ kind: MissionKind, by amount: Int) {
        refreshDailyMissionsIfNeeded()
        var didChange = false
        for index in dailyMissions.indices where dailyMissions[index].kind == kind {
            let nextProgress = min(dailyMissions[index].target, dailyMissions[index].progress + amount)
            if nextProgress != dailyMissions[index].progress {
                dailyMissions[index].progress = nextProgress
                didChange = true
            }
        }
        if didChange {
            saveDailyMissions()
            updateMissionRewards()
        }
    }

    private func updateScoreMission() {
        refreshDailyMissionsIfNeeded()
        var didChange = false
        for index in dailyMissions.indices where dailyMissions[index].kind == .score {
            let nextProgress = min(dailyMissions[index].target, max(dailyMissions[index].progress, score))
            if nextProgress != dailyMissions[index].progress {
                dailyMissions[index].progress = nextProgress
                didChange = true
            }
        }
        if didChange {
            saveDailyMissions()
            updateMissionRewards()
        }
    }

    private func updateMissionRewards() {
        let defaults = UserDefaults.standard
        var rewardedIDs = Set(defaults.stringArray(forKey: rewardedMissionIDsKey) ?? [])
        var newlyCompletedCount = 0

        for mission in dailyMissions where mission.isCompleted && !rewardedIDs.contains(mission.id) {
            rewardedIDs.insert(mission.id)
            newlyCompletedCount += 1
        }

        guard newlyCompletedCount > 0 else { return }
        completedMissionCount += newlyCompletedCount
        defaults.set(completedMissionCount, forKey: completedMissionCountKey)
        defaults.set(Array(rewardedIDs), forKey: rewardedMissionIDsKey)
    }

    private func saveDailyMissions() {
        guard let data = try? JSONEncoder().encode(dailyMissions) else { return }
        UserDefaults.standard.set(data, forKey: dailyMissionsKey)
        UserDefaults.standard.set(Self.todayKey(), forKey: dailyMissionsDateKey)
    }

    private static func loadRunRecords(from defaults: UserDefaults, key: String) -> [RunRecord] {
        guard
            let data = defaults.data(forKey: key),
            let records = try? JSONDecoder().decode([RunRecord].self, from: data)
        else {
            return []
        }

        return Array(records.prefix(30))
    }

    private static func loadDailyMissions(from defaults: UserDefaults, missionsKey: String, dateKey: String) -> [DailyMission] {
        let today = todayKey()
        guard
            defaults.string(forKey: dateKey) == today,
            let data = defaults.data(forKey: missionsKey),
            let missions = try? JSONDecoder().decode([DailyMission].self, from: data),
            !missions.isEmpty
        else {
            let generated = generateDailyMissions(for: today)
            if let data = try? JSONEncoder().encode(generated) {
                defaults.set(data, forKey: missionsKey)
                defaults.set(today, forKey: dateKey)
            }
            return generated
        }

        return missions
    }

    private static func generateDailyMissions(for dayKey: String) -> [DailyMission] {
        let seed = abs(dayKey.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 10_000 })
        let scoreTarget = [40, 60, 80, 100][seed % 4]
        let sparkTarget = [18, 24, 30, 36][seed % 4]
        let feverTarget = [1, 2, 2, 3][seed % 4]
        let shieldTarget = [1, 2, 3, 3][seed % 4]
        let pool: [(MissionKind, Int)] = [
            (.score, scoreTarget),
            (.sparks, sparkTarget),
            (.fever, feverTarget),
            (.shields, shieldTarget)
        ]

        let startIndex = seed % pool.count
        return (0..<3).map { offset in
            let item = pool[(startIndex + offset) % pool.count]
            return DailyMission(
                id: "\(dayKey)-\(item.0.rawValue)",
                kind: item.0,
                target: item.1,
                progress: 0
            )
        }
    }

    private static func todayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func updatePauseState() {
        isPaused = isLoading || isStartScreenPresented || !hasSeenTutorial || isGameOver || isSettingsPresented || isUserPaused || !isSceneActive
    }
}
