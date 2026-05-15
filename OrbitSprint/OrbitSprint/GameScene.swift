import SpriteKit

final class GameScene: SKScene {
    private enum NodeName {
        static let player = "player"
        static let shard = "shard"
        static let spark = "spark"
        static let shield = "shield"
        static let slow = "slow"
        static let star = "star"
    }

    private let state: GameState
    private let innerRadius: CGFloat = 86
    private let outerRadius: CGFloat = 136
    private let playerRadius: CGFloat = 14
    private var currentRadius: CGFloat = 86
    private var angle: CGFloat = -.pi / 2
    private var angularSpeed: CGFloat = 1.72
    private var lastUpdate: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    private var safeUntil: TimeInterval = 1.6
    private var spawnTimer: TimeInterval = 0
    private var sparkTimer: TimeInterval = 0
    private var powerUpTimer: TimeInterval = 0
    private var comboTimer: TimeInterval = 0
    private var difficulty: CGFloat = 1
    private var renderedTheme: GameTheme?

    private lazy var player = SKShapeNode(circleOfRadius: playerRadius)
    private let orbitLayer = SKNode()
    private let objectLayer = SKNode()

    init(state: GameState) {
        self.state = state
        super.init(size: .zero)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isMultipleTouchEnabled = false
        setupScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        drawOrbits()
        drawStars()
        updatePlayerPosition()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !state.isGameOver else { return }
        guard !state.isPaused else { return }
        currentRadius = currentRadius == innerRadius ? outerRadius : innerRadius
        angularSpeed *= -1
        SoundPlayer.tap(enabled: state.isSoundEnabled)
        Haptics.tap(enabled: state.isHapticsEnabled)
    }

    override func update(_ currentTime: TimeInterval) {
        if renderedTheme != state.selectedTheme {
            applyTheme()
        }

        guard !state.isPaused else { return }
        let delta = lastUpdate > 0 ? min(currentTime - lastUpdate, 1 / 20) : 0
        lastUpdate = currentTime
        elapsedTime += delta

        difficulty = 1 + min(CGFloat(state.score) * 0.012, 1.45)
        let timeScale: CGFloat = state.slowTimeRemaining > 0 ? 0.62 : 1
        angle += angularSpeed * difficulty * timeScale * CGFloat(delta)
        spawnTimer += delta
        sparkTimer += delta
        powerUpTimer += delta
        comboTimer += delta
        state.tick(delta: delta)

        if comboTimer > max(1.45, 2.4 - Double(state.level) * 0.08) {
            state.breakCombo()
        }

        if elapsedTime > safeUntil, spawnTimer > max(0.62, 1.42 - Double(state.level) * 0.052) {
            spawnShard()
            spawnTimer = 0
        }

        if elapsedTime > 0.45, sparkTimer > max(0.58, 0.92 - Double(state.level) * 0.018) {
            spawnSpark()
            sparkTimer = 0
        }

        if powerUpTimer > max(4.2, 8.2 - Double(state.level) * 0.24) {
            spawnPowerUp()
            powerUpTimer = 0
        }

        updatePlayerPosition()
        checkCollisions()
    }

    private func setupScene() {
        removeAllChildren()
        addChild(orbitLayer)
        addChild(objectLayer)

        player.name = NodeName.player
        player.strokeColor = .white
        player.lineWidth = 3
        player.glowWidth = 7
        addChild(player)
        player.alpha = 0.64
        player.run(.sequence([.wait(forDuration: safeUntil), .fadeAlpha(to: 1, duration: 0.25)]))

        applyTheme()
        drawStars()
        drawOrbits()
        updatePlayerPosition()
    }

    private func applyTheme() {
        renderedTheme = state.selectedTheme
        player.fillColor = state.selectedTheme.playerColor
        drawOrbits()
        for node in objectLayer.children {
            guard let shape = node as? SKShapeNode else { continue }
            if shape.name == NodeName.spark {
                shape.fillColor = state.selectedTheme.sparkColor
            } else if shape.name == NodeName.shard {
                shape.fillColor = state.selectedTheme.shardColor
            } else if shape.name == NodeName.shield {
                shape.fillColor = SKColor(red: 0.2, green: 0.72, blue: 1.0, alpha: 1)
            } else if shape.name == NodeName.slow {
                shape.fillColor = SKColor(red: 0.64, green: 0.38, blue: 1.0, alpha: 1)
            }
        }
    }

    private func drawOrbits() {
        orbitLayer.removeAllChildren()

        for radius in [innerRadius, outerRadius] {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = SKColor.white.withAlphaComponent(radius == innerRadius ? 0.18 : 0.28)
            ring.lineWidth = 2
            ring.glowWidth = 1
            orbitLayer.addChild(ring)
        }

        let core = SKShapeNode(circleOfRadius: 42)
        core.position = center
        core.fillColor = state.selectedTheme.sparkColor.withAlphaComponent(0.12)
        core.strokeColor = state.selectedTheme.sparkColor.withAlphaComponent(0.44)
        core.lineWidth = 2
        core.glowWidth = 8
        orbitLayer.addChild(core)
    }

    private func drawStars() {
        children.filter { $0.name == NodeName.star }.forEach { $0.removeFromParent() }
        for _ in 0..<42 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.4))
            star.name = NodeName.star
            star.position = CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
            star.fillColor = .white.withAlphaComponent(CGFloat.random(in: 0.18...0.56))
            star.strokeColor = .clear
            star.zPosition = -2
            addChild(star)
        }
    }

    private func spawnShard() {
        let radius = chooseThreatRadius()
        let spawnAngle = nextPlayableSpawnAngle(minLead: 0.95, maxLead: 1.78)
        guard canSpawnThreat(at: spawnAngle) else { return }

        let node = SKShapeNode(rectOf: CGSize(width: 22, height: 22), cornerRadius: 4)
        node.name = NodeName.shard
        node.position = point(on: radius, angle: spawnAngle)
        node.zRotation = CGFloat.random(in: 0...(2 * .pi))
        node.fillColor = state.selectedTheme.shardColor
        node.strokeColor = .white.withAlphaComponent(0.42)
        node.lineWidth = 2
        node.glowWidth = 5
        node.userData = ["radius": radius, "angle": spawnAngle]
        objectLayer.addChild(node)

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: TimeInterval(CGFloat.random(in: 1.0...1.8)))
        node.run(.repeatForever(spin))
        node.run(.sequence([.wait(forDuration: 6.0), .fadeOut(withDuration: 0.25), .removeFromParent()]))

        if CGFloat.random(in: 0...1) < 0.58 {
            spawnSpark(on: oppositeRadius(from: radius), near: spawnAngle + CGFloat.random(in: -0.18...0.18))
        }
    }

    private func spawnSpark() {
        let spawnAngle = nextPlayableSpawnAngle(minLead: 0.72, maxLead: 2.35)
        let radius = Bool.random() ? innerRadius : outerRadius
        spawnSpark(on: radius, near: spawnAngle)
    }

    private func spawnSpark(on radius: CGFloat, near spawnAngle: CGFloat) {
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.24, names: [NodeName.spark]) else { return }

        let node = SKShapeNode(circleOfRadius: 9)
        node.name = NodeName.spark
        node.position = point(on: radius, angle: spawnAngle)
        node.fillColor = state.selectedTheme.sparkColor
        node.strokeColor = .white
        node.lineWidth = 2
        node.glowWidth = 8
        node.userData = ["radius": radius, "angle": spawnAngle]
        objectLayer.addChild(node)
        let pulse = SKAction.sequence([.scale(to: 1.25, duration: 0.35), .scale(to: 1.0, duration: 0.35)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.2), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func spawnPowerUp() {
        let radius = Bool.random() ? innerRadius : outerRadius
        let spawnAngle = nextPlayableSpawnAngle(minLead: 1.05, maxLead: 2.4)
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.34, names: [NodeName.shard, NodeName.shield, NodeName.slow]) else { return }

        let isShield = state.shieldCharges == 0 || Bool.random()
        let node: SKShapeNode

        if isShield {
            node = SKShapeNode(rectOf: CGSize(width: 25, height: 25), cornerRadius: 7)
            node.name = NodeName.shield
            node.fillColor = SKColor(red: 0.2, green: 0.72, blue: 1.0, alpha: 1)
        } else {
            node = SKShapeNode(circleOfRadius: 12)
            node.name = NodeName.slow
            node.fillColor = SKColor(red: 0.64, green: 0.38, blue: 1.0, alpha: 1)
        }

        node.position = point(on: radius, angle: spawnAngle)
        node.strokeColor = .white
        node.lineWidth = 2
        node.glowWidth = 9
        node.userData = ["radius": radius, "angle": spawnAngle]
        objectLayer.addChild(node)

        let pulse = SKAction.sequence([.scale(to: 1.2, duration: 0.4), .scale(to: 0.92, duration: 0.4)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.8), .fadeOut(withDuration: 0.22), .removeFromParent()]))
    }

    private func checkCollisions() {
        for node in objectLayer.children {
            guard player.frame.insetBy(dx: -3, dy: -3).intersects(node.frame) else { continue }

            if node.name == NodeName.spark {
                node.removeFromParent()
                comboTimer = 0
                state.collectSpark()
                Haptics.collect(enabled: state.isHapticsEnabled)
                flash(color: state.selectedTheme.sparkColor.withAlphaComponent(0.18))
            } else if node.name == NodeName.shield {
                node.removeFromParent()
                comboTimer = 0
                state.grantShield()
                Haptics.collect(enabled: state.isHapticsEnabled)
                flash(color: SKColor(red: 0.2, green: 0.72, blue: 1.0, alpha: 0.18))
            } else if node.name == NodeName.slow {
                node.removeFromParent()
                comboTimer = 0
                state.triggerSlowTime(duration: 4.0)
                Haptics.collect(enabled: state.isHapticsEnabled)
                flash(color: SKColor(red: 0.64, green: 0.38, blue: 1.0, alpha: 0.18))
            } else if node.name == NodeName.shard {
                guard elapsedTime > safeUntil else {
                    node.removeFromParent()
                    flash(color: SKColor.white.withAlphaComponent(0.12))
                    continue
                }
                if state.consumeShield() {
                    node.removeFromParent()
                    Haptics.fail(enabled: state.isHapticsEnabled)
                    flash(color: SKColor(red: 0.2, green: 0.72, blue: 1.0, alpha: 0.2))
                    continue
                }
                Haptics.fail(enabled: state.isHapticsEnabled)
                state.endGame()
                player.run(.sequence([.scale(to: 1.45, duration: 0.08), .scale(to: 0.1, duration: 0.16)]))
                flash(color: state.selectedTheme.shardColor.withAlphaComponent(0.24))
            }
        }
    }

    private func flash(color: SKColor) {
        let node = SKShapeNode(rectOf: size)
        node.position = center
        node.fillColor = color
        node.strokeColor = .clear
        node.zPosition = 20
        addChild(node)
        node.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
    }

    private func updatePlayerPosition() {
        player.position = point(on: currentRadius, angle: angle)
    }

    private func point(on radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func chooseThreatRadius() -> CGFloat {
        let playerWillReachSoon = CGFloat.random(in: 0...1) < 0.64
        if playerWillReachSoon {
            return currentRadius
        }
        return Bool.random() ? innerRadius : outerRadius
    }

    private func oppositeRadius(from radius: CGFloat) -> CGFloat {
        radius == innerRadius ? outerRadius : innerRadius
    }

    private func nextPlayableSpawnAngle(minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let direction: CGFloat = angularSpeed >= 0 ? 1 : -1
        return normalizedAngle(angle + direction * CGFloat.random(in: minLead...maxLead))
    }

    private func canSpawnThreat(at spawnAngle: CGFloat) -> Bool {
        if angularDistance(angle, spawnAngle) < 0.82 {
            return false
        }

        return !hasNearbyObject(
            at: spawnAngle,
            clearance: state.level < 6 ? 0.58 : 0.46,
            names: [NodeName.shard]
        )
    }

    private func hasNearbyObject(at spawnAngle: CGFloat, clearance: CGFloat, names: Set<String>) -> Bool {
        objectLayer.children.contains { node in
            guard let name = node.name, names.contains(name) else { return false }
            guard let objectAngle = storedAngle(for: node) else { return false }
            return angularDistance(objectAngle, spawnAngle) < clearance
        }
    }

    private func storedAngle(for node: SKNode) -> CGFloat? {
        if let angle = node.userData?["angle"] as? CGFloat {
            return angle
        }

        if let angle = node.userData?["angle"] as? NSNumber {
            return CGFloat(truncating: angle)
        }

        return nil
    }

    private func angularDistance(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        let difference = abs(normalizedAngle(first) - normalizedAngle(second))
        return min(difference, 2 * .pi - difference)
    }

    private func normalizedAngle(_ value: CGFloat) -> CGFloat {
        var angle = value.truncatingRemainder(dividingBy: 2 * .pi)
        if angle < 0 {
            angle += 2 * .pi
        }
        return angle
    }

    private var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
