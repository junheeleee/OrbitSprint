import AVFoundation

enum SoundPlayer {
    private static var players: [String: AVAudioPlayer] = [:]

    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        preload("tap")
        preload("collect")
        preload("fail")
    }

    static func tap(enabled: Bool) {
        play("tap", enabled: enabled)
    }

    static func collect(enabled: Bool) {
        play("collect", enabled: enabled)
    }

    static func fail(enabled: Bool) {
        play("fail", enabled: enabled)
    }

    private static func preload(_ name: String) {
        guard players[name] == nil else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        players[name] = player
    }

    private static func play(_ name: String, enabled: Bool) {
        guard enabled else { return }
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.play()
    }
}
