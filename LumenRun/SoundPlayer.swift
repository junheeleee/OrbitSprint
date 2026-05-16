import AVFoundation

enum SoundPlayer {
    private static var players: [String: AVAudioPlayer] = [:]
    private static var musicPlayer: AVAudioPlayer?
    private static var feverMusicPlayer: AVAudioPlayer?
    private static var isFeverActive = false
    private static var lastPlayTimes: [String: TimeInterval] = [:]

    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        preload("tap")
        preload("lumen")
        preload("shield")
        preload("timecore")
        preload("crash")
        preload("shieldbreak")
        preload("fever")
        preloadMusic()
    }

    static func tap(enabled: Bool) {
        play("tap", enabled: enabled)
    }

    static func lumen(enabled: Bool) {
        play("lumen", enabled: enabled)
    }

    static func shield(enabled: Bool) {
        play("shield", enabled: enabled)
    }

    static func timeCore(enabled: Bool) {
        play("timecore", enabled: enabled)
    }

    static func shieldBreak(enabled: Bool) {
        play("shieldbreak", enabled: enabled)
    }

    static func crash(enabled: Bool) {
        play("crash", enabled: enabled)
    }

    static func feverStart(enabled: Bool) {
        play("fever", enabled: enabled)
    }

    static func setMusicEnabled(_ enabled: Bool) {
        guard enabled else {
            musicPlayer?.pause()
            feverMusicPlayer?.pause()
            return
        }

        if isFeverActive {
            musicPlayer?.pause()
            if feverMusicPlayer?.isPlaying == false {
                feverMusicPlayer?.play()
            }
        } else if let musicPlayer, !musicPlayer.isPlaying {
            feverMusicPlayer?.pause()
            musicPlayer.play()
        }
    }

    static func setFeverActive(_ active: Bool, enabled: Bool) {
        isFeverActive = active
        guard enabled else { return }

        if active {
            musicPlayer?.pause()
            if feverMusicPlayer?.isPlaying == false {
                feverMusicPlayer?.currentTime = 0
                feverMusicPlayer?.play()
            }
        } else {
            feverMusicPlayer?.pause()
            if musicPlayer?.isPlaying == false {
                musicPlayer?.play()
            }
        }
    }

    private static func preload(_ name: String) {
        guard players[name] == nil else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        players[name] = player
    }

    private static func preloadMusic() {
        guard musicPlayer == nil else { return }
        guard let url = Bundle.main.url(forResource: "background", withExtension: "wav") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0.32
        player.prepareToPlay()
        musicPlayer = player

        if let feverURL = Bundle.main.url(forResource: "feverloop", withExtension: "wav"),
           let feverPlayer = try? AVAudioPlayer(contentsOf: feverURL) {
            feverPlayer.numberOfLoops = -1
            feverPlayer.volume = 0.38
            feverPlayer.prepareToPlay()
            feverMusicPlayer = feverPlayer
        }
    }

    private static func play(_ name: String, enabled: Bool) {
        guard enabled else { return }
        guard let player = players[name] else { return }
        guard canPlay(name) else { return }
        lastPlayTimes[name] = ProcessInfo.processInfo.systemUptime
        player.currentTime = 0
        player.play()
    }

    private static func canPlay(_ name: String) -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let minimumInterval: TimeInterval
        switch name {
        case "lumen":
            minimumInterval = isFeverActive ? 0.07 : 0.035
        case "tap":
            minimumInterval = 0.035
        default:
            minimumInterval = 0
        }

        guard minimumInterval > 0 else { return true }
        return now - (lastPlayTimes[name] ?? -10) >= minimumInterval
    }
}
