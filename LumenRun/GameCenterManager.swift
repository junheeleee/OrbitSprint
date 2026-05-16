import GameKit
import SwiftUI
import UIKit

@MainActor
final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    static let highScoreLeaderboardID = "com.junpacstudio.lumenrun.highscore"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var playerAlias = ""
    @Published private(set) var lastSubmissionSucceeded = false
    @Published private(set) var lastSubmissionError: String?
    @Published var isShowingLeaderboard = false

    private var pendingScore: Int?

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                if let viewController {
                    self.present(viewController)
                    return
                }

                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.playerAlias = GKLocalPlayer.local.alias
                self.lastSubmissionError = error?.localizedDescription

                if self.isAuthenticated, let pendingScore = self.pendingScore {
                    self.pendingScore = nil
                    self.submit(score: pendingScore)
                }
            }
        }
    }

    func submit(score: Int) {
        guard score > 0 else { return }
        lastSubmissionSucceeded = false
        lastSubmissionError = nil

        guard GKLocalPlayer.local.isAuthenticated else {
            pendingScore = max(pendingScore ?? 0, score)
            authenticate()
            return
        }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.highScoreLeaderboardID]
        ) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.lastSubmissionSucceeded = error == nil
                self.lastSubmissionError = error?.localizedDescription
            }
        }
    }

    func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }

        isShowingLeaderboard = true
    }

    private func present(_ viewController: UIViewController) {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return
        }

        var presenter = rootViewController
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(viewController, animated: true)
    }
}

struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(
            leaderboardID: GameCenterManager.highScoreLeaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
