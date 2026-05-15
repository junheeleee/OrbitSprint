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
    private let playerRadius: CGFloat = 14
    private let orbitRadii: [CGFloat] = [76, 112, 148]
    private let collisionRadiusTolerance: CGFloat = 20
    private var currentRadius: CGFloat = 76
    private var targetRadius: CGFloat = 76
    private var currentOrbitIndex = 0
    private var orbitStepDirection = 1
    private var angle: CGFloat = -.pi / 2
    private var angularSpeed: CGFloat = 1.72
    private var lastUpdate: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    private var safeUntil: TimeInterval = 1.6
    private var invulnerableUntil: TimeInterval = 0
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
        switchOrbitAndDirection()
    }

    private func switchOrbitAndDirection() {
        guard !state.isGameOver else { return }
        guard !state.isPaused else { return }
        advanceOrbit()
        angularSpeed *= -1
        SoundPlayer.tap(enabled: state.isSoundEnabled)
        Haptics.tap(enabled: state.isHapticsEnabled)
    }

    private func advanceOrbit() {
        currentOrbitIndex += orbitStepDirection
        if currentOrbitIndex >= orbitRadii.count - 1 {
            currentOrbitIndex = orbitRadii.count - 1
        } else if currentOrbitIndex <= 0 {
            currentOrbitIndex = 0
        }
        updateOrbitStepDirectionForEdge()
        targetRadius = orbitRadii[currentOrbitIndex]
    }

    private func updateOrbitStepDirectionForEdge() {
        if currentOrbitIndex >= orbitRadii.count - 1 {
            orbitStepDirection = -1
        } else if currentOrbitIndex <= 0 {
            orbitStepDirection = 1
        }
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
        currentRadius += (targetRadius - currentRadius) * min(1, CGFloat(delta) * 14)
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
        targetRadius = currentRadius
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

        for (index, radius) in orbitRadii.enumerated() {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = SKColor.white.withAlphaComponent(0.16 + CGFloat(index) * 0.08)
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
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.95, maxLead: 1.78)
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
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + CGFloat.random(in: -0.18...0.18))
        }
    }

    private func spawnSpark() {
        let spawnAngle = nextPlayableSpawnAngle(minLead: 0.72, maxLead: 2.35)
        let radius = randomOrbitRadius()
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
        let radius = randomOrbitRadius()
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
            guard isOnCollidingRadius(with: node) else { continue }
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
                    absorbShard(node, invulnerabilityDuration: 0.8)
                    continue
                }
                guard elapsedTime > invulnerableUntil else {
                    absorbShard(node, invulnerabilityDuration: 0.55)
                    continue
                }
                if state.consumeShield() {
                    absorbShard(node, invulnerabilityDuration: 1.15)
                    Haptics.fail(enabled: state.isHapticsEnabled)
                    flash(color: SKColor(red: 0.2, green: 0.72, blue: 1.0, alpha: 0.2))
                    continue
                }
                Haptics.fail(enabled: state.isHapticsEnabled)
                node.removeFromParent()
                removeNearbyShards(clearance: 0.9)
                state.endGame()
                player.run(.sequence([.scale(to: 1.45, duration: 0.08), .scale(to: 0.1, duration: 0.16)]))
                flash(color: state.selectedTheme.shardColor.withAlphaComponent(0.24))
                return
            }
        }
    }

    private func absorbShard(_ node: SKNode, invulnerabilityDuration: TimeInterval) {
        node.removeFromParent()
        invulnerableUntil = max(invulnerableUntil, elapsedTime + invulnerabilityDuration)
        recoverToSafePosition()
        pulseInvulnerability()
    }

    private func recoverToSafePosition() {
        angle = safestRecoveryAngle()
        currentRadius = saferRecoveryRadius(at: angle)
        currentOrbitIndex = nearestOrbitIndex(to: currentRadius)
        updateOrbitStepDirectionForEdge()
        targetRadius = currentRadius
        updatePlayerPosition()
        removeNearbyShards(clearance: 1.15)
        spawnTimer = 0
        sparkTimer = min(sparkTimer, 0.2)
    }

    private func safestRecoveryAngle() -> CGFloat {
        let candidates = (0..<16).map { normalizedAngle(CGFloat($0) * .pi / 8) }
        let shardAngles = objectLayer.children.compactMap { node -> CGFloat? in
            guard node.name == NodeName.shard else { return nil }
            return storedAngle(for: node)
        }

        guard !shardAngles.isEmpty else {
            return normalizedAngle(angle + .pi)
        }

        return candidates.max { first, second in
            nearestDistance(from: first, to: shardAngles) < nearestDistance(from: second, to: shardAngles)
        } ?? normalizedAngle(angle + .pi)
    }

    private func saferRecoveryRadius(at recoveryAngle: CGFloat) -> CGFloat {
        orbitRadii.min { first, second in
            shardRisk(on: first, near: recoveryAngle) < shardRisk(on: second, near: recoveryAngle)
        } ?? orbitRadii[0]
    }

    private func shardRisk(on radius: CGFloat, near recoveryAngle: CGFloat) -> CGFloat {
        objectLayer.children.reduce(CGFloat.zero) { total, node in
            guard node.name == NodeName.shard else { return total }
            guard let objectAngle = storedAngle(for: node) else { return total }
            guard let objectRadius = storedRadius(for: node) else { return total }
            let lanePenalty: CGFloat = objectRadius == radius ? 1 : 0.34
            return total + lanePenalty / max(angularDistance(objectAngle, recoveryAngle), 0.12)
        }
    }

    private func removeNearbyShards(clearance: CGFloat) {
        objectLayer.children.forEach { node in
            guard node.name == NodeName.shard else { return }
            guard let objectAngle = storedAngle(for: node) else { return }
            if angularDistance(objectAngle, angle) < clearance {
                node.removeFromParent()
            }
        }
    }

    private func pulseInvulnerability() {
        player.removeAction(forKey: "invulnerablePulse")
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.42, duration: 0.08),
            .fadeAlpha(to: 0.9, duration: 0.08)
        ])
        player.run(.repeat(pulse, count: 6), withKey: "invulnerablePulse")
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
            return targetRadius
        }
        return randomOrbitRadius()
    }

    private func randomOrbitRadius() -> CGFloat {
        orbitRadii.randomElement() ?? orbitRadii[0]
    }

    private func rewardRadius(awayFrom radius: CGFloat) -> CGFloat {
        let index = nearestOrbitIndex(to: radius)
        if index == 0 {
            return orbitRadii[1]
        }
        if index == orbitRadii.count - 1 {
            return orbitRadii[orbitRadii.count - 2]
        }
        return Bool.random() ? orbitRadii[index - 1] : orbitRadii[index + 1]
    }

    private func nearestOrbitIndex(to radius: CGFloat) -> Int {
        orbitRadii.indices.min { first, second in
            abs(orbitRadii[first] - radius) < abs(orbitRadii[second] - radius)
        } ?? 0
    }

    private func isOnCollidingRadius(with node: SKNode) -> Bool {
        guard let objectRadius = storedRadius(for: node) else { return true }
        return abs(objectRadius - currentRadius) <= collisionRadiusTolerance
    }

    private func nextThreatSpawnAngle(on radius: CGFloat, minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let radiusIndex = nearestOrbitIndex(to: radius)
        if radiusIndex == nearestOrbitIndex(to: currentRadius) || radiusIndex == currentOrbitIndex {
            return nextTrailingSpawnAngle(minLead: minLead, maxLead: maxLead)
        }
        return nextPlayableSpawnAngle(minLead: minLead, maxLead: maxLead)
    }

    private func nextPlayableSpawnAngle(minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let direction: CGFloat = angularSpeed >= 0 ? 1 : -1
        return normalizedAngle(angle + direction * CGFloat.random(in: minLead...maxLead))
    }

    private func nextTrailingSpawnAngle(minLead: CGFloat, maxLead: CGFloat) -> CGFloat {
        let direction: CGFloat = angularSpeed >= 0 ? 1 : -1
        return normalizedAngle(angle - direction * CGFloat.random(in: minLead...maxLead))
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

    private func storedRadius(for node: SKNode) -> CGFloat? {
        if let radius = node.userData?["radius"] as? CGFloat {
            return radius
        }

        if let radius = node.userData?["radius"] as? NSNumber {
            return CGFloat(truncating: radius)
        }

        return nil
    }

    private func nearestDistance(from angle: CGFloat, to angles: [CGFloat]) -> CGFloat {
        angles.map { angularDistance(angle, $0) }.min() ?? .pi
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
