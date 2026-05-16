import UIKit

enum Haptics {
    private static let tapGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let collectGenerator = UINotificationFeedbackGenerator()
    private static let failGenerator = UINotificationFeedbackGenerator()

    static func configure() {
        tapGenerator.prepare()
        collectGenerator.prepare()
        failGenerator.prepare()
    }

    static func tap(enabled: Bool) {
        guard enabled else { return }
        tapGenerator.impactOccurred()
        tapGenerator.prepare()
    }

    static func collect(enabled: Bool) {
        guard enabled else { return }
        collectGenerator.notificationOccurred(.success)
        collectGenerator.prepare()
    }

    static func fail(enabled: Bool) {
        guard enabled else { return }
        failGenerator.notificationOccurred(.error)
        failGenerator.prepare()
    }
}
