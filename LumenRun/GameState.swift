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

enum RunUpgradeKind: CaseIterable, Hashable {
    case shieldCache
    case magnetBoost
    case timeBend
    case feverCharge
    case scoreSurge
    case comboEngine
    case overclock
}

struct RunUpgradeChoice: Identifiable, Equatable {
    let kind: RunUpgradeKind
    let titleKey: String
    let descriptionKey: String
    let iconName: String

    var id: RunUpgradeKind { kind }
}

struct RunBuildSummary: Identifiable, Equatable {
    let kind: RunUpgradeKind
    let titleKey: String
    let iconName: String
    let count: Int

    var id: RunUpgradeKind { kind }
}

enum AchievementID: String, CaseIterable, Codable {
    case firstRun
    case firstFever
    case score50
    case score100
    case score200
    case shields5
    case runs10
    case newBest5
    case dailySweep
}

struct AchievementDefinition: Identifiable, Equatable {
    let id: AchievementID
    let titleKey: String
    let descriptionKey: String
    let iconName: String
    let target: Int

    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: .firstRun, titleKey: "achievements.firstRun.title", descriptionKey: "achievements.firstRun.desc", iconName: "play.fill", target: 1),
        AchievementDefinition(id: .firstFever, titleKey: "achievements.firstFever.title", descriptionKey: "achievements.firstFever.desc", iconName: "flame.fill", target: 1),
        AchievementDefinition(id: .score50, titleKey: "achievements.score50.title", descriptionKey: "achievements.score50.desc", iconName: "50.circle.fill", target: 50),
        AchievementDefinition(id: .score100, titleKey: "achievements.score100.title", descriptionKey: "achievements.score100.desc", iconName: "100.circle.fill", target: 100),
        AchievementDefinition(id: .score200, titleKey: "achievements.score200.title", descriptionKey: "achievements.score200.desc", iconName: "bolt.circle.fill", target: 200),
        AchievementDefinition(id: .shields5, titleKey: "achievements.shields5.title", descriptionKey: "achievements.shields5.desc", iconName: "shield.fill", target: 5),
        AchievementDefinition(id: .runs10, titleKey: "achievements.runs10.title", descriptionKey: "achievements.runs10.desc", iconName: "repeat.circle.fill", target: 10),
        AchievementDefinition(id: .newBest5, titleKey: "achievements.newBest5.title", descriptionKey: "achievements.newBest5.desc", iconName: "crown.fill", target: 5),
        AchievementDefinition(id: .dailySweep, titleKey: "achievements.dailySweep.title", descriptionKey: "achievements.dailySweep.desc", iconName: "checkmark.seal.fill", target: 1)
    ]
}

final class GameState: ObservableObject {
    @Published var score = 0
    @Published var bestScore: Int
    @Published private(set) var previousBestScore: Int
    @Published private(set) var runRecords: [RunRecord]
    @Published private(set) var dailyMissions: [DailyMission]
    @Published private(set) var achievementProgress: [String: Int]
    @Published var achievementToast: AchievementDefinition?
    @Published var combo = 0
    @Published var multiplier = 1
    @Published var level = 1
    @Published private(set) var stage = 1
    @Published private(set) var stageTargetScore = 120
    @Published private(set) var clearedStage = 0
    @Published private(set) var stageClearSerial = 0
    @Published private(set) var stageResumeSerial = 0
    @Published private(set) var runUpgradeCounts: [RunUpgradeKind: Int] = [:]
    @Published var shieldCharges = 0
    @Published var shieldTimeRemaining: TimeInterval = 0
    @Published var slowTimeRemaining: TimeInterval = 0
    @Published var magnetTimeRemaining: TimeInterval = 0
    @Published var feverRemaining: TimeInterval = 0
    @Published private(set) var runUpgradeChoices: [RunUpgradeChoice] = []
    @Published var isRunUpgradePresented = false {
        didSet { updatePauseState() }
    }
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
    @Published var isAchievementsPresented = false {
        didSet { updatePauseState() }
    }
    @Published var isRewardsPresented = false {
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
    @Published var selectedCoreSkin: CoreSkin {
        didSet {
            if !isCoreSkinUnlocked(selectedCoreSkin) {
                selectedCoreSkin = .orb
                return
            }
            UserDefaults.standard.set(selectedCoreSkin.rawValue, forKey: selectedCoreSkinKey)
        }
    }

    private let bestScoreKey = "bestScore"
    private let runRecordsKey = "runRecords"
    private let dailyMissionsKey = "dailyMissions"
    private let dailyMissionsDateKey = "dailyMissionsDate"
    private let completedMissionCountKey = "completedMissionCount"
    private let rewardedMissionIDsKey = "rewardedMissionIDs"
    private let achievementProgressKey = "achievementProgress"
    private let tutorialKey = "hasSeenTutorial"
    private let soundEnabledKey = "soundEnabled"
    private let hapticsEnabledKey = "hapticsEnabled"
    private let selectedThemeKey = "selectedTheme"
    private let selectedCoreSkinKey = "selectedCoreSkin"
    private let feverComboThreshold = 13
    private let feverDuration: TimeInterval = 5.4
    private let shieldDuration: TimeInterval = 8.5
    private let shieldExtensionDuration: TimeInterval = 6
    private let magnetDuration: TimeInterval = 5.5
    private var nextStageScore = 120
    private var recentRunUpgradeKinds: [RunUpgradeKind] = []
    private var canShowAchievementToast = false
    private var pendingAchievementToasts: [AchievementDefinition] = []

    var isFeverActive: Bool {
        feverRemaining > 0
    }

    var feverComboGoal: Int {
        feverComboThreshold
    }

    var feverProgress: Double {
        guard !isFeverActive else { return 1 }
        return min(1, Double(combo) / Double(feverComboThreshold))
    }

    var comboUntilFever: Int {
        guard !isFeverActive else { return 0 }
        return max(0, feverComboThreshold - combo)
    }

    var stageRouteTitleKey: String {
        switch stage % 4 {
        case 1:
            return "stage.route.flow"
        case 2:
            return "stage.route.harvest"
        case 3:
            return "stage.route.gate"
        default:
            return "stage.route.overdrive"
        }
    }

    var activeBuildSummaries: [RunBuildSummary] {
        runUpgradeCounts
            .sorted {
                if $0.value == $1.value {
                    return upgradeSortIndex($0.key) < upgradeSortIndex($1.key)
                }
                return $0.value > $1.value
            }
            .prefix(4)
            .map { kind, count in
                RunBuildSummary(
                    kind: kind,
                    titleKey: upgradeTitleKey(for: kind),
                    iconName: upgradeIconName(for: kind),
                    count: count
                )
            }
    }

    var topRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.score > $1.score }.prefix(5))
    }

    var recentRunRecords: [RunRecord] {
        Array(runRecords.sorted { $0.date > $1.date }.prefix(5))
    }

    var didSetNewBestThisRun: Bool {
        isGameOver && score > previousBestScore
    }

    var bestScoreDelta: Int {
        score - previousBestScore
    }

    var completedDailyMissionTotal: Int {
        dailyMissions.filter(\.isCompleted).count
    }

    var completedAchievementCount: Int {
        AchievementDefinition.all.filter { isAchievementUnlocked($0) }.count
    }

    var nextLockedTheme: GameTheme? {
        GameTheme.allCases.first { !isThemeUnlocked($0) }
    }

    var missionsUntilNextTheme: Int? {
        guard let nextLockedTheme else { return nil }
        return max(0, nextLockedTheme.unlockRequirement - completedMissionCount)
    }

    init() {
        let defaults = UserDefaults.standard
        let loadedBestScore = defaults.integer(forKey: bestScoreKey)
        bestScore = loadedBestScore
        previousBestScore = loadedBestScore
        runRecords = Self.loadRunRecords(from: defaults, key: runRecordsKey)
        dailyMissions = Self.loadDailyMissions(from: defaults, missionsKey: dailyMissionsKey, dateKey: dailyMissionsDateKey)
        achievementProgress = Self.loadAchievementProgress(from: defaults, key: achievementProgressKey)
        hasSeenTutorial = defaults.bool(forKey: tutorialKey)
        isPaused = true
        isSoundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        isHapticsEnabled = defaults.object(forKey: hapticsEnabledKey) as? Bool ?? true
        completedMissionCount = defaults.integer(forKey: completedMissionCountKey)
        selectedTheme = GameTheme(rawValue: defaults.string(forKey: selectedThemeKey) ?? "") ?? .aurora
        selectedCoreSkin = CoreSkin(rawValue: defaults.string(forKey: selectedCoreSkinKey) ?? "") ?? .orb
        if selectedTheme.unlockRequirement > completedMissionCount {
            selectedTheme = .aurora
        }
        if selectedCoreSkin.unlockRequirement > completedMissionCount {
            selectedCoreSkin = .orb
        }
        updateMissionRewards()
        canShowAchievementToast = true
    }

    func reset() {
        previousBestScore = bestScore
        score = 0
        combo = 0
        multiplier = 1
        level = 1
        stage = 1
        stageTargetScore = 120
        clearedStage = 0
        stageClearSerial = 0
        stageResumeSerial = 0
        runUpgradeCounts = [:]
        shieldCharges = 0
        shieldTimeRemaining = 0
        slowTimeRemaining = 0
        magnetTimeRemaining = 0
        feverRemaining = 0
        runUpgradeChoices = []
        isRunUpgradePresented = false
        nextStageScore = 120
        recentRunUpgradeKinds = []
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
                setAchievementProgress(.firstFever, to: 1)
                SoundPlayer.feverStart(enabled: isSoundEnabled)
                SoundPlayer.setFeverActive(true, enabled: isSoundEnabled)
            }
        }

        multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
        score += multiplier + (isFeverActive ? 1 : 0)
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        advanceMission(.sparks, by: 1)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectFeverHit() {
        guard isFeverActive else { return }
        score += max(3, multiplier + 2)
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectSurge() {
        if !isFeverActive {
            combo += 2
        }
        multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
        score += max(8, multiplier * 3)
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func collectBombClear(count: Int) {
        guard count > 0 else { return }
        combo += min(count, 3)
        multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
        score += max(4, count * 4) * multiplier
        level = max(1, score / 25 + 1)
        SoundPlayer.lumen(enabled: isSoundEnabled)
        updateScoreMission()
        updateScoreAchievements()
        updateBestScore()
        offerRunUpgradeIfNeeded()
    }

    func chooseRunUpgrade(_ choice: RunUpgradeChoice) {
        guard isRunUpgradePresented else { return }
        applyRunUpgrade(choice.kind)
        runUpgradeChoices = []
        isRunUpgradePresented = false
        stageResumeSerial += 1
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
        incrementAchievement(.shields5, by: 1)
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

    func triggerMagnet() {
        magnetTimeRemaining = max(magnetTimeRemaining, magnetDuration)
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

        if magnetTimeRemaining > 0 {
            magnetTimeRemaining = max(0, magnetTimeRemaining - delta)
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
        let didBeatPreviousBest = finalScore > previousBestScore
        feverRemaining = 0
        updateScoreMission()
        recordRun(score: finalScore, level: level)
        incrementAchievement(.firstRun, by: 1)
        incrementAchievement(.runs10, by: 1)
        if didBeatPreviousBest {
            incrementAchievement(.newBest5, by: 1)
        }
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

    func showAchievements() {
        isAchievementsPresented = true
    }

    func closeAchievements() {
        isAchievementsPresented = false
    }

    func showRewards() {
        isRewardsPresented = true
    }

    func closeRewards() {
        isRewardsPresented = false
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

    func isCoreSkinUnlocked(_ skin: CoreSkin) -> Bool {
        completedMissionCount >= skin.unlockRequirement
    }

    func achievementProgress(for achievement: AchievementDefinition) -> Int {
        min(achievementProgress[achievement.id.rawValue] ?? 0, achievement.target)
    }

    func isAchievementUnlocked(_ achievement: AchievementDefinition) -> Bool {
        achievementProgress(for: achievement) >= achievement.target
    }

    func dismissAchievementToast(_ achievement: AchievementDefinition? = nil) {
        guard achievement == nil || achievementToast?.id == achievement?.id else { return }
        achievementToast = nil
        if !pendingAchievementToasts.isEmpty {
            achievementToast = pendingAchievementToasts.removeFirst()
        }
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
        if completedDailyMissionTotal >= dailyMissions.count {
            setAchievementProgress(.dailySweep, to: 1)
        }
    }

    private func updateScoreAchievements() {
        setAchievementProgress(.score50, to: score)
        setAchievementProgress(.score100, to: score)
        setAchievementProgress(.score200, to: score)
    }

    private func incrementAchievement(_ id: AchievementID, by amount: Int) {
        let nextValue = (achievementProgress[id.rawValue] ?? 0) + amount
        setAchievementProgress(id, to: nextValue)
    }

    private func setAchievementProgress(_ id: AchievementID, to value: Int) {
        guard let definition = AchievementDefinition.all.first(where: { $0.id == id }) else { return }
        let currentValue = achievementProgress[id.rawValue] ?? 0
        let wasUnlocked = currentValue >= definition.target
        let nextValue = min(value, definition.target)
        guard nextValue > currentValue else { return }
        achievementProgress[id.rawValue] = nextValue
        saveAchievementProgress()

        if !wasUnlocked, nextValue >= definition.target, canShowAchievementToast {
            showAchievementToast(definition)
        }
    }

    private func showAchievementToast(_ achievement: AchievementDefinition) {
        if achievementToast == nil {
            achievementToast = achievement
        } else if achievementToast?.id != achievement.id, !pendingAchievementToasts.contains(where: { $0.id == achievement.id }) {
            pendingAchievementToasts.append(achievement)
        }
    }

    private func saveAchievementProgress() {
        guard let data = try? JSONEncoder().encode(achievementProgress) else { return }
        UserDefaults.standard.set(data, forKey: achievementProgressKey)
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

    private static func loadAchievementProgress(from defaults: UserDefaults, key: String) -> [String: Int] {
        guard
            let data = defaults.data(forKey: key),
            let progress = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }

        return progress
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
        isPaused = isLoading || isStartScreenPresented || !hasSeenTutorial || isGameOver || isSettingsPresented || isAchievementsPresented || isRewardsPresented || isRunUpgradePresented || isUserPaused || !isSceneActive
    }

    private func offerRunUpgradeIfNeeded() {
        guard !isRunUpgradePresented, !isGameOver, score >= nextStageScore else { return }
        clearedStage = stage
        runUpgradeChoices = makeRunUpgradeChoices()
        stageClearSerial += 1
        let nextStage = stage + 1
        stage = nextStage
        nextStageScore += stageScoreRequirement(for: nextStage)
        stageTargetScore = nextStageScore
        isRunUpgradePresented = true
    }

    private func makeRunUpgradeChoices() -> [RunUpgradeChoice] {
        let pool: [RunUpgradeChoice] = [
            RunUpgradeChoice(kind: .shieldCache, titleKey: "upgrade.shield.title", descriptionKey: "upgrade.shield.desc", iconName: "shield.fill"),
            RunUpgradeChoice(kind: .magnetBoost, titleKey: "upgrade.magnet.title", descriptionKey: "upgrade.magnet.desc", iconName: "dot.radiowaves.left.and.right"),
            RunUpgradeChoice(kind: .timeBend, titleKey: "upgrade.slow.title", descriptionKey: "upgrade.slow.desc", iconName: "hourglass"),
            RunUpgradeChoice(kind: .feverCharge, titleKey: "upgrade.fever.title", descriptionKey: "upgrade.fever.desc", iconName: "flame.fill"),
            RunUpgradeChoice(kind: .scoreSurge, titleKey: "upgrade.score.title", descriptionKey: "upgrade.score.desc", iconName: "bolt.fill"),
            RunUpgradeChoice(kind: .comboEngine, titleKey: "upgrade.combo.title", descriptionKey: "upgrade.combo.desc", iconName: "link.circle.fill"),
            RunUpgradeChoice(kind: .overclock, titleKey: "upgrade.overclock.title", descriptionKey: "upgrade.overclock.desc", iconName: "speedometer")
        ]
        let freshPool = pool.filter { !recentRunUpgradeKinds.contains($0.kind) }
        let choicePool = freshPool.count >= 3 ? freshPool : pool
        let seed = max(0, score / 11 + stage * 5 + combo * 2 + clearedStage)

        return (0..<min(3, choicePool.count)).map { offset in
            choicePool[(seed + offset * 3) % choicePool.count]
        }
    }

    private func applyRunUpgrade(_ kind: RunUpgradeKind) {
        recentRunUpgradeKinds.append(kind)
        recentRunUpgradeKinds = Array(recentRunUpgradeKinds.suffix(2))
        runUpgradeCounts[kind, default: 0] += 1

        switch kind {
        case .shieldCache:
            grantShield()
        case .magnetBoost:
            magnetTimeRemaining = max(magnetTimeRemaining, magnetDuration + 2)
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        case .timeBend:
            triggerSlowTime(duration: 5.5)
        case .feverCharge:
            if isFeverActive {
                feverRemaining = min(feverRemaining + 2.5, feverDuration + 3)
            } else {
                combo = min(feverComboThreshold - 1, combo + 5)
                multiplier = min(5, 1 + combo / 5)
            }
            SoundPlayer.feverStart(enabled: isSoundEnabled)
        case .scoreSurge:
            score += max(10, multiplier * 8)
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .comboEngine:
            combo += 5
            multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
            SoundPlayer.lumen(enabled: isSoundEnabled)
        case .overclock:
            score += max(16, multiplier * 9)
            combo += 3
            multiplier = min(isFeverActive ? 8 : 5, 1 + combo / 5)
            level = max(1, score / 25 + 1)
            updateScoreMission()
            updateScoreAchievements()
            updateBestScore()
            SoundPlayer.timeCore(enabled: isSoundEnabled)
        }
    }

    private func stageScoreRequirement(for stage: Int) -> Int {
        170 + min(stage - 2, 6) * 50
    }

    private func upgradeTitleKey(for kind: RunUpgradeKind) -> String {
        switch kind {
        case .shieldCache:
            return "upgrade.shield.title"
        case .magnetBoost:
            return "upgrade.magnet.title"
        case .timeBend:
            return "upgrade.slow.title"
        case .feverCharge:
            return "upgrade.fever.title"
        case .scoreSurge:
            return "upgrade.score.title"
        case .comboEngine:
            return "upgrade.combo.title"
        case .overclock:
            return "upgrade.overclock.title"
        }
    }

    private func upgradeIconName(for kind: RunUpgradeKind) -> String {
        switch kind {
        case .shieldCache:
            return "shield.fill"
        case .magnetBoost:
            return "dot.radiowaves.left.and.right"
        case .timeBend:
            return "hourglass"
        case .feverCharge:
            return "flame.fill"
        case .scoreSurge:
            return "bolt.fill"
        case .comboEngine:
            return "link.circle.fill"
        case .overclock:
            return "speedometer"
        }
    }

    private func upgradeSortIndex(_ kind: RunUpgradeKind) -> Int {
        RunUpgradeKind.allCases.firstIndex(of: kind) ?? 0
    }
}
