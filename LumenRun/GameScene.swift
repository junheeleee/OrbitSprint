import SpriteKit

final class GameScene: SKScene {
    private enum RunPattern: CaseIterable {
        case flow
        case gate
        case switchback
        case harvest
        case overdrive
    }

    private enum NodeName {
        static let player = "player"
        static let star = "star"
        static let feverPulse = "feverPulse"
    }

    private let state: GameState
    private let playerRadius: CGFloat = 14
    private let orbitRadii: [CGFloat] = [76, 112, 148]
    private let collisionRadiusTolerance: CGFloat = 9
    private let powerUpBlockerNames = Set([
        LumenObjectKind.shard.nodeName,
        LumenObjectKind.shield.nodeName,
        LumenObjectKind.slow.nodeName,
        LumenObjectKind.magnet.nodeName,
        LumenObjectKind.bomb.nodeName,
        LumenObjectKind.surge.nodeName
    ])
    private let orbitTransitionDuration: TimeInterval = 0.16
    private var currentRadius: CGFloat = 76
    private var targetRadius: CGFloat = 76
    private var orbitStartRadius: CGFloat = 76
    private var orbitTransitionElapsed: TimeInterval = 0
    private var currentOrbitIndex = 0
    private var orbitStepDirection = 1
    private var angle: CGFloat = -.pi / 2
    private var previousAngle: CGFloat = -.pi / 2
    private var angularSpeed: CGFloat = 1.72
    private var lastUpdate: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0
    private var safeUntil: TimeInterval = 1.6
    private var invulnerableUntil: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var sparkTimer: TimeInterval = 0
    private var powerUpTimer: TimeInterval = 0
    private var comboTimer: TimeInterval = 0
    private var cleanupTimer: TimeInterval = 0
    private var patternTimer: TimeInterval = 0
    private var patternWaveTimer: TimeInterval = 0
    private var patternDuration: TimeInterval = 8.5
    private var patternIndex = 0
    private var patternStep = 0
    private var currentPattern: RunPattern = .flow
    private var lastScreenFlashTime: TimeInterval = -10
    private var lastFeverFlashTime: TimeInterval = -10
    private var didSpawnOpeningRoute = false
    private var difficulty: CGFloat = 1
    private var renderedTheme: GameTheme?
    private var renderedCoreSkin: CoreSkin?
    private var renderedFeverActive = false
    private var renderedShieldCharges = -1

    private lazy var player = SKShapeNode(circleOfRadius: playerRadius)
    private lazy var shieldAura = SKShapeNode(path: shieldPath(radius: 30))
    private let orbitLayer = SKNode()
    private let objectLayer = SKNode()
    private let effectLayer = SKNode()

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
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
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
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = 0
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
        if renderedTheme != state.selectedTheme || renderedCoreSkin != state.selectedCoreSkin {
            applyTheme()
        }
        if renderedFeverActive != state.isFeverActive {
            renderedFeverActive = state.isFeverActive
            drawOrbits()
            if state.isFeverActive {
                triggerFeverBurst()
                convertNearbyShardsForFever()
            }
        }
        if renderedShieldCharges != state.shieldCharges {
            renderedShieldCharges = state.shieldCharges
            refreshShieldAura()
        }

        guard !state.isPaused else { return }
        let delta = lastUpdate > 0 ? min(currentTime - lastUpdate, 1 / 20) : 0
        lastUpdate = currentTime
        elapsedTime += delta

        difficulty = 1 + CGFloat(difficultyProgress) * 0.85
        let timeScale: CGFloat = state.slowTimeRemaining > 0 ? 0.62 : 1
        let feverScale: CGFloat = state.isFeverActive ? 1.65 : 1
        previousAngle = angle
        angle += angularSpeed * difficulty * timeScale * feverScale * CGFloat(delta)
        updateOrbitRadius(delta: delta)
        spawnTimer += delta
        sparkTimer += delta
        powerUpTimer += delta
        comboTimer += delta
        cleanupTimer += delta
        patternTimer += delta
        patternWaveTimer += delta
        state.tick(delta: delta)

        if comboTimer > scaledInterval(easy: 3.1, hard: 1.75) {
            state.breakCombo()
        }

        updateRunPattern()
        updatePatternSpawns()

        if powerUpTimer > scaledInterval(easy: 8.8, hard: 4.8) {
            spawnPowerUp()
            powerUpTimer = 0
        }

        updatePlayerPosition()
        updateMagnetPull(delta: delta)
        checkCollisions()
        cleanupTransientNodesIfNeeded()
    }

    private func setupScene() {
        removeAllChildren()
        resetRunState()
        addChild(orbitLayer)
        addChild(objectLayer)
        addChild(effectLayer)

        player.name = NodeName.player
        player.strokeColor = .white
        player.zPosition = 5
        addChild(player)
        setupShieldAura()
        player.alpha = 1
        targetRadius = currentRadius
        player.run(.sequence([.scale(to: 0.82, duration: 0.1), .scale(to: 1.0, duration: 0.28)]), withKey: "spawnPulse")

        applyTheme()
        drawStars()
        drawOrbits()
        updatePlayerPosition()
    }

    private func resetRunState() {
        currentRadius = orbitRadii[0]
        targetRadius = orbitRadii[0]
        orbitStartRadius = orbitRadii[0]
        orbitTransitionElapsed = orbitTransitionDuration
        currentOrbitIndex = 0
        orbitStepDirection = 1
        angle = -.pi / 2
        previousAngle = angle
        angularSpeed = abs(angularSpeed)
        lastUpdate = 0
        elapsedTime = 0
        safeUntil = 1.6
        invulnerableUntil = 0
        spawnTimer = 0
        sparkTimer = 0
        powerUpTimer = 0
        comboTimer = 0
        cleanupTimer = 0
        patternTimer = 0
        patternWaveTimer = 0
        patternDuration = 8.5
        patternIndex = 0
        patternStep = 0
        currentPattern = .flow
        lastScreenFlashTime = -10
        lastFeverFlashTime = -10
        didSpawnOpeningRoute = false
        difficulty = 1
        renderedShieldCharges = -1
        renderedFeverActive = state.isFeverActive

        resetPlayerVisuals()
        shieldAura.removeAllActions()
        shieldAura.setScale(1)
        shieldAura.alpha = 0
    }

    private func resetPlayerVisuals() {
        player.removeAllActions()
        player.setScale(1)
        player.alpha = 1
        player.isHidden = false
    }

    private func applyTheme() {
        renderedTheme = state.selectedTheme
        renderedCoreSkin = state.selectedCoreSkin
        player.path = playerPath(for: state.selectedCoreSkin)
        player.fillColor = state.selectedTheme.playerColor
        player.lineWidth = state.selectedCoreSkin.lineWidth
        player.glowWidth = state.selectedCoreSkin.glowWidth
        refreshShieldAura()
        drawOrbits()
        for node in objectLayer.children {
            guard let shape = node as? SKShapeNode else { continue }
            guard let kind = shape.lumenObjectKind else { continue }
            shape.fillColor = objectColor(for: kind)
            shape.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        }
    }

    private func drawOrbits() {
        orbitLayer.removeAllChildren()

        for (index, radius) in orbitRadii.enumerated() {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = state.isFeverActive
                ? state.selectedTheme.feverColor.withAlphaComponent(0.35 + CGFloat(index) * 0.12)
                : SKColor.white.withAlphaComponent(0.16 + CGFloat(index) * 0.08)
            ring.lineWidth = state.isFeverActive ? 3 : 2
            ring.glowWidth = state.isFeverActive ? 7 : 1
            orbitLayer.addChild(ring)
        }

        let core = SKShapeNode(circleOfRadius: 42)
        core.position = center
        core.fillColor = (state.isFeverActive ? state.selectedTheme.feverColor : state.selectedTheme.sparkColor).withAlphaComponent(0.12)
        core.strokeColor = (state.isFeverActive ? state.selectedTheme.feverColor : state.selectedTheme.sparkColor).withAlphaComponent(0.44)
        core.lineWidth = state.isFeverActive ? 3 : 2
        core.glowWidth = state.isFeverActive ? 16 : 8
        orbitLayer.addChild(core)

        if state.isFeverActive {
            let pulse = SKShapeNode(circleOfRadius: orbitRadii.last ?? 148)
            pulse.name = NodeName.feverPulse
            pulse.position = center
            pulse.strokeColor = state.selectedTheme.feverColor.withAlphaComponent(0.4)
            pulse.lineWidth = 1
            pulse.glowWidth = 16
            pulse.run(.repeatForever(.sequence([
                .group([.scale(to: 1.08, duration: 0.45), .fadeAlpha(to: 0.08, duration: 0.45)]),
                .group([.scale(to: 1.0, duration: 0.05), .fadeAlpha(to: 0.7, duration: 0.05)])
            ])))
            orbitLayer.addChild(pulse)
        }
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

    private func updateRunPattern() {
        guard elapsedTime > safeUntil + 2 else { return }
        guard patternTimer >= patternDuration else { return }

        patternIndex += 1
        let sequence = availablePatternSequence()
        currentPattern = sequence[patternIndex % sequence.count]
        patternTimer = 0
        patternWaveTimer = 0
        patternStep = 0
        patternDuration = scaledInterval(easy: 11.5, hard: 7.4)
        telegraphPatternStart(currentPattern)
    }

    private func availablePatternSequence() -> [RunPattern] {
        if state.score < 35 {
            return [.flow, .harvest]
        }
        if state.score < 90 {
            return [.flow, .harvest, .gate]
        }
        if state.score < 160 {
            return [.flow, .gate, .harvest, .switchback]
        }
        return [.gate, .switchback, .harvest, .overdrive]
    }

    private func updatePatternSpawns() {
        guard elapsedTime > safeUntil else { return }

        if !didSpawnOpeningRoute {
            didSpawnOpeningRoute = true
            spawnOpeningRoute()
        }

        switch currentPattern {
        case .flow:
            if spawnTimer > scaledInterval(easy: 1.72, hard: 0.78) {
                spawnShard()
                spawnTimer = 0
            }
            if elapsedTime > 0.45, sparkTimer > scaledInterval(easy: 1.08, hard: 0.64) {
                spawnSpark()
                if state.score >= 45, patternStep.isMultiple(of: 5) {
                    spawnChoiceFork()
                }
                patternStep += 1
                sparkTimer = 0
            }
        case .gate:
            if spawnTimer > scaledInterval(easy: 2.05, hard: 1.12) {
                spawnGateWave()
                spawnTimer = 0
            }
            if sparkTimer > scaledInterval(easy: 1.2, hard: 0.76) {
                spawnSpark()
                sparkTimer = 0
            }
        case .switchback:
            if patternWaveTimer > scaledInterval(easy: 1.15, hard: 0.66) {
                spawnSwitchbackStep()
                patternWaveTimer = 0
            }
            if sparkTimer > scaledInterval(easy: 1.12, hard: 0.74) {
                spawnSpark(on: orbitRadii[patternStep % orbitRadii.count], near: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.74))
                sparkTimer = 0
            }
        case .harvest:
            if sparkTimer > scaledInterval(easy: 0.72, hard: 0.38) {
                spawnSparkTrail()
                sparkTimer = 0
            }
            if state.score >= 45, patternWaveTimer > scaledInterval(easy: 3.2, hard: 2.1) {
                spawnPowerUp(kind: .magnet, on: randomOrbitRadius(), near: nextPlayableSpawnAngle(minLead: 0.9, maxLead: 2.1))
                patternWaveTimer = 0
            }
            if spawnTimer > scaledInterval(easy: 2.65, hard: 1.45) {
                spawnShard()
                spawnTimer = 0
            }
        case .overdrive:
            if spawnTimer > scaledInterval(easy: 1.12, hard: 0.55) {
                if patternStep.isMultiple(of: 3) {
                    spawnChoiceFork()
                } else {
                    spawnShard()
                }
                patternStep += 1
                spawnTimer = 0
            }
            if sparkTimer > scaledInterval(easy: 0.9, hard: 0.52) {
                spawnSpark()
                sparkTimer = 0
            }
            if patternWaveTimer > scaledInterval(easy: 2.2, hard: 1.45) {
                spawnPowerUp(kind: .surge, on: randomOrbitRadius(), near: nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.9))
                patternWaveTimer = 0
            }
        }
    }

    private func spawnOpeningRoute() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.82, maxLead: 1.16)
        for offset in 0..<5 {
            let index = offset % orbitRadii.count
            spawnSpark(on: orbitRadii[index], near: baseAngle + CGFloat(offset) * 0.22)
        }
        spawnPowerUp(kind: .shield, on: orbitRadii[1], near: baseAngle + 0.52)
        pulseOrbit(at: orbitRadii[0], color: state.selectedTheme.sparkColor, duration: 0.48)
    }

    private func spawnGateWave() {
        let safeIndex = reachableSafeLaneIndex()
        let waveAngle = nextPlayableSpawnAngle(minLead: 1.06, maxLead: 1.62)
        pulseOrbit(at: orbitRadii[safeIndex], color: state.selectedTheme.shieldColor, duration: 0.48)
        for index in orbitRadii.indices where index != safeIndex {
            spawnShard(on: orbitRadii[index], near: waveAngle + CGFloat.random(in: -0.04...0.04), rewardChance: 0, allowParallel: true)
        }
        spawnSpark(on: orbitRadii[safeIndex], near: waveAngle + CGFloat.random(in: -0.08...0.08))
        if state.score >= 70 {
            let riskyIndex = (safeIndex + orbitStepDirection + orbitRadii.count) % orbitRadii.count
            spawnPowerUp(kind: .surge, on: orbitRadii[riskyIndex], near: waveAngle + 0.24)
        }
        if patternStep.isMultiple(of: 3) {
            spawnPowerUp(kind: .shield, on: orbitRadii[safeIndex], near: waveAngle - 0.2)
        }
        patternStep += 1
    }

    private func spawnSwitchbackStep() {
        let laneSequence = [0, 1, 2, 1]
        let laneIndex = laneSequence[patternStep % laneSequence.count]
        let radius = orbitRadii[laneIndex]
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.82, maxLead: 1.42)
        pulseOrbit(at: radius, color: state.selectedTheme.shardColor, duration: 0.32)
        spawnShard(on: radius, near: spawnAngle, rewardChance: patternStep.isMultiple(of: 2) ? 0.45 : 0.18, allowParallel: false)
        if state.score >= 120, patternStep % 5 == 4 {
            spawnPowerUp(kind: .bomb, on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.16)
        } else if patternStep.isMultiple(of: 3) {
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + 0.22)
        }
        patternStep += 1
    }

    private func spawnSparkTrail() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.66, maxLead: 1.9)
        let startIndex = Int.random(in: orbitRadii.indices)
        let direction = Bool.random() ? 1 : -1
        for offset in 0..<3 {
            let rawIndex = startIndex + offset * direction + orbitRadii.count
            let index = rawIndex % orbitRadii.count
            spawnSpark(on: orbitRadii[index], near: baseAngle + CGFloat(offset) * 0.18)
        }
        if state.score >= 75, patternStep.isMultiple(of: 4) {
            spawnPowerUp(kind: .magnet, on: orbitRadii[startIndex], near: baseAngle - 0.2)
        }
        patternStep += 1
    }

    private func spawnChoiceFork() {
        let baseAngle = nextPlayableSpawnAngle(minLead: 0.92, maxLead: 1.64)
        let safeIndex = reachableSafeLaneIndex()
        let riskyIndex = rewardLaneIndex(awayFrom: safeIndex)
        let safeRadius = orbitRadii[safeIndex]
        let riskyRadius = orbitRadii[riskyIndex]

        pulseOrbit(at: safeRadius, color: state.selectedTheme.sparkColor, duration: 0.34)
        pulseOrbit(at: riskyRadius, color: objectColor(for: .surge), duration: 0.34)
        spawnSpark(on: safeRadius, near: baseAngle - 0.08)
        spawnSpark(on: safeRadius, near: baseAngle + 0.12)
        spawnPowerUp(kind: .surge, on: riskyRadius, near: baseAngle + 0.04)
        spawnShard(on: riskyRadius, near: baseAngle - 0.28, rewardChance: 0, allowParallel: true)
        spawnShard(on: riskyRadius, near: baseAngle + 0.34, rewardChance: 0, allowParallel: true)
    }

    private func rewardLaneIndex(awayFrom index: Int) -> Int {
        if index == 0 {
            return 2
        }
        if index == orbitRadii.count - 1 {
            return 0
        }
        return Bool.random() ? 0 : 2
    }

    private func reachableSafeLaneIndex() -> Int {
        min(max(currentOrbitIndex + orbitStepDirection, orbitRadii.startIndex), orbitRadii.index(before: orbitRadii.endIndex))
    }

    private func telegraphPatternStart(_ pattern: RunPattern) {
        switch pattern {
        case .flow:
            break
        case .gate:
            pulseOrbit(at: orbitRadii[reachableSafeLaneIndex()], color: state.selectedTheme.shieldColor, duration: 0.72)
        case .switchback:
            pulseOrbit(at: orbitRadii[1], color: state.selectedTheme.shardColor, duration: 0.5)
        case .harvest:
            orbitRadii.forEach { pulseOrbit(at: $0, color: state.selectedTheme.sparkColor, duration: 0.46) }
        case .overdrive:
            orbitRadii.forEach { pulseOrbit(at: $0, color: state.selectedTheme.feverColor, duration: 0.62) }
            flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.12))
        }
    }

    private func pulseOrbit(at radius: CGFloat, color: SKColor, duration: TimeInterval) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = center
        ring.strokeColor = color.withAlphaComponent(0.72)
        ring.lineWidth = 4
        ring.glowWidth = 12
        ring.zPosition = 11
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 1.08, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func shockwave(at point: CGPoint, color: SKColor, radius: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.position = point
        ring.strokeColor = color.withAlphaComponent(0.78)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.glowWidth = 14
        ring.zPosition = 12
        effectLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: radius / 10, duration: 0.34),
                .fadeOut(withDuration: 0.34)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnShard() {
        let radius = chooseThreatRadius()
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.95, maxLead: 1.78)
        spawnShard(on: radius, near: spawnAngle, rewardChance: 0.58, allowParallel: false)
    }

    private func spawnShard(on radius: CGFloat, near spawnAngle: CGFloat, rewardChance: CGFloat, allowParallel: Bool) {
        guard canSpawnThreat(at: spawnAngle, on: radius, allowParallel: allowParallel) else { return }

        let kind = LumenObjectKind.shard
        let node = SKShapeNode(path: hazardShardPath(radius: kind.baseRadius))
        node.name = kind.nodeName
        node.position = point(on: radius, angle: spawnAngle)
        node.zRotation = CGFloat.random(in: 0...(2 * .pi))
        node.fillColor = objectColor(for: kind)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle]
        addSymbol(to: node, path: dangerMarkPath(size: kind.baseRadius * 1.07), color: .black.withAlphaComponent(0.66), lineWidth: 2.4)
        objectLayer.addChild(node)

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: TimeInterval(CGFloat.random(in: 0.75...1.15)))
        let pulse = SKAction.sequence([.scale(to: 1.07, duration: 0.18), .scale(to: 1.0, duration: 0.18)])
        node.run(.repeatForever(spin))
        node.run(.repeatForever(pulse), withKey: "dangerPulse")
        node.run(.sequence([.wait(forDuration: 6.0), .fadeOut(withDuration: 0.25), .removeFromParent()]))

        if CGFloat.random(in: 0...1) < rewardChance {
            spawnSpark(on: rewardRadius(awayFrom: radius), near: spawnAngle + CGFloat.random(in: -0.18...0.18))
        }
    }

    private func spawnSpark() {
        let spawnAngle = nextPlayableSpawnAngle(minLead: 0.72, maxLead: 2.35)
        let radius = randomOrbitRadius()
        spawnSpark(on: radius, near: spawnAngle)
    }

    private func spawnSpark(on radius: CGFloat, near spawnAngle: CGFloat) {
        let kind = LumenObjectKind.spark
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.24, names: [kind.nodeName]) else { return }

        let node = SKShapeNode(path: starPath(outerRadius: kind.baseRadius, innerRadius: kind.baseRadius * 0.42, points: 5))
        node.name = kind.nodeName
        node.position = point(on: radius, angle: spawnAngle)
        node.fillColor = objectColor(for: kind)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle]
        addSymbol(to: node, path: smallCirclePath(radius: kind.baseRadius * 0.28), color: .white.withAlphaComponent(0.76), lineWidth: 1.2)
        objectLayer.addChild(node)
        let pulse = SKAction.sequence([.scale(to: 1.16, duration: 0.35), .scale(to: 1.0, duration: 0.35)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.2), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func spawnPowerUp() {
        let radius = randomOrbitRadius()
        let spawnAngle = nextPlayableSpawnAngle(minLead: 1.05, maxLead: 2.4)
        let roll = CGFloat.random(in: 0...1)
        spawnPowerUp(kind: selectedPowerUpKind(for: roll), on: radius, near: spawnAngle)
    }

    private func selectedPowerUpKind(for roll: CGFloat) -> LumenObjectKind {
        if state.score >= 120 && roll < 0.16 {
            return .bomb
        }
        if state.score >= 70 && roll < 0.32 {
            return .surge
        }
        if state.score >= 45 && roll < 0.48 {
            return .magnet
        }
        if state.shieldCharges == 0 || roll < 0.72 {
            return .shield
        }
        return .slow
    }

    private func spawnPowerUp(kind: LumenObjectKind, on radius: CGFloat, near spawnAngle: CGFloat) {
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.34, names: powerUpBlockerNames) else { return }

        let node: SKShapeNode

        if kind == .bomb {
            node = SKShapeNode(path: burstPath(outerRadius: kind.baseRadius * 1.12, innerRadius: kind.baseRadius * 0.46, points: 8))
            addSymbol(to: node, path: clearSlashPath(size: kind.baseRadius * 1.35), color: .white.withAlphaComponent(0.92), lineWidth: 2.6)
        } else if kind == .surge {
            node = SKShapeNode(path: hexPath(radius: kind.baseRadius))
            addSymbol(to: node, path: lightningPath(size: kind.baseRadius * 1.16), color: .white.withAlphaComponent(0.9), lineWidth: 2)
        } else if kind == .magnet {
            node = SKShapeNode(path: magnetBodyPath(radius: kind.baseRadius))
            addSymbol(to: node, path: pullArrowPath(size: kind.baseRadius * 1.25), color: .white.withAlphaComponent(0.9), lineWidth: 2.4)
        } else if kind == .shield {
            node = SKShapeNode(path: shieldPath(radius: kind.baseRadius))
            addSymbol(to: node, path: checkPath(size: kind.baseRadius * 1.25), color: .white.withAlphaComponent(0.92), lineWidth: 2.5)
        } else {
            node = SKShapeNode(path: hourglassPath(radius: kind.baseRadius))
            addHourglassSand(to: node, radius: kind.baseRadius)
        }

        node.name = kind.nodeName
        node.fillColor = objectColor(for: kind)
        node.position = point(on: radius, angle: spawnAngle)
        node.strokeColor = kind.sceneStrokeColor(for: state.selectedTheme)
        node.lineWidth = kind.lineWidth
        node.glowWidth = kind.glowWidth
        node.userData = ["radius": radius, "angle": spawnAngle]
        objectLayer.addChild(node)

        let pulse = SKAction.sequence([.scale(to: 1.12, duration: 0.4), .scale(to: 0.96, duration: 0.4)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.8), .fadeOut(withDuration: 0.22), .removeFromParent()]))
    }

    private func checkCollisions() {
        for node in objectLayer.children {
            guard node.alpha > 0.08 else { continue }
            guard isOnCollidingRadius(with: node) else { continue }
            guard isTouchingPlayer(node) else { continue }
            guard let kind = node.lumenObjectKind else { continue }

            if kind == .spark {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSpark()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: state.isFeverActive ? state.selectedTheme.feverColor : state.selectedTheme.sparkColor, count: state.isFeverActive ? 8 : 9)
                if state.isFeverActive {
                    throttledFeverFlash(color: state.selectedTheme.feverColor.withAlphaComponent(0.18))
                } else {
                    flash(color: state.selectedTheme.sparkColor.withAlphaComponent(0.16))
                }
            } else if kind == .shield {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.grantShield()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: state.selectedTheme.shieldColor, count: 14)
                flash(color: state.selectedTheme.shieldColor.withAlphaComponent(0.18))
            } else if kind == .slow {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.triggerSlowTime(duration: 4.0)
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: state.selectedTheme.timeCoreColor, count: 14)
                flash(color: state.selectedTheme.timeCoreColor.withAlphaComponent(0.18))
            } else if kind == .magnet {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.triggerMagnet()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: objectColor(for: .magnet), count: 14)
                pulseOrbit(at: currentRadius, color: objectColor(for: .magnet), duration: 0.42)
                flash(color: objectColor(for: .magnet).withAlphaComponent(0.16))
            } else if kind == .bomb {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                let cleared = clearShards(near: hitPoint, clearance: 118)
                state.collectBombClear(count: cleared)
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: objectColor(for: .bomb), count: max(18, cleared * 8))
                shockwave(at: hitPoint, color: objectColor(for: .bomb), radius: 118)
                flash(color: objectColor(for: .bomb).withAlphaComponent(0.18))
            } else if kind == .surge {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSurge()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: objectColor(for: .surge), count: state.isFeverActive ? 10 : 18)
                flash(color: objectColor(for: .surge).withAlphaComponent(0.2))
            } else if kind == .shard {
                if state.isFeverActive {
                    let hitPoint = node.position
                    node.removeFromParent()
                    comboTimer = 0
                    state.collectFeverHit()
                    Haptics.collect(enabled: state.isHapticsEnabled)
                    emitBurst(at: hitPoint, color: state.selectedTheme.feverColor, count: 10)
                    throttledFeverFlash(color: state.selectedTheme.feverColor.withAlphaComponent(0.18))
                    continue
                }
                guard elapsedTime > safeUntil else {
                    absorbShard(node, invulnerabilityDuration: 0.8)
                    continue
                }
                guard elapsedTime > invulnerableUntil else {
                    absorbShard(node, invulnerabilityDuration: 0.55)
                    continue
                }
                if state.consumeShield() {
                    let hitPoint = node.position
                    absorbShard(node, invulnerabilityDuration: 1.15)
                    Haptics.fail(enabled: state.isHapticsEnabled)
                    emitBurst(at: hitPoint, color: state.selectedTheme.shieldColor, count: 18)
                    flash(color: state.selectedTheme.shieldColor.withAlphaComponent(0.2))
                    continue
                }
                Haptics.fail(enabled: state.isHapticsEnabled)
                node.removeFromParent()
                removeNearbyShards(clearance: 0.9)
                state.endGame()
                player.run(
                    .sequence([
                        .scale(to: 1.45, duration: 0.08),
                        .scale(to: 0.1, duration: 0.16),
                        .run { [weak self] in
                            self?.resetPlayerVisuals()
                        }
                    ]),
                    withKey: "deathPulse"
                )
                flash(color: state.selectedTheme.shardColor.withAlphaComponent(0.24))
                return
            }
        }
    }

    private func updateMagnetPull(delta: TimeInterval) {
        guard state.magnetTimeRemaining > 0 else { return }

        var movedSparkCount = 0
        let captureRadiusSquared: CGFloat = 18 * 18
        let pullRadiusSquared: CGFloat = 108 * 108
        let pull = min(CGFloat(delta) * 8.4, 0.24)

        for node in objectLayer.children {
            guard node.lumenObjectKind == .spark else { continue }
            guard movedSparkCount < 6 else { return }

            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let distanceSquared = dx * dx + dy * dy
            guard distanceSquared < pullRadiusSquared else { continue }

            if distanceSquared <= captureRadiusSquared {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSpark()
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: state.selectedTheme.sparkColor, count: 3)
                continue
            }

            movedSparkCount += 1
            let nextX = node.position.x + dx * pull
            let nextY = node.position.y + dy * pull
            node.position = CGPoint(x: nextX, y: nextY)
        }
    }

    private func clearShards(near point: CGPoint, clearance: CGFloat) -> Int {
        var cleared = 0
        objectLayer.children.forEach { node in
            guard node.lumenObjectKind == .shard else { return }
            let distance = hypot(point.x - node.position.x, point.y - node.position.y)
            guard distance <= clearance else { return }
            cleared += 1
            emitBurst(at: node.position, color: objectColor(for: .bomb), count: 6)
            node.removeFromParent()
        }
        return cleared
    }

    private func cleanupTransientNodesIfNeeded() {
        guard cleanupTimer >= 0.45 else { return }
        cleanupTimer = 0
        trimOldestChildren(in: effectLayer, keeping: state.isFeverActive ? 42 : 56)
        trimOldestChildren(in: objectLayer, keeping: state.isFeverActive ? 42 : 52)
    }

    private func trimOldestChildren(in layer: SKNode, keeping limit: Int) {
        let overflow = layer.children.count - limit
        guard overflow > 0 else { return }
        layer.children.prefix(overflow).forEach { $0.removeFromParent() }
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
        orbitStartRadius = currentRadius
        orbitTransitionElapsed = orbitTransitionDuration
        targetRadius = currentRadius
        updatePlayerPosition()
        removeNearbyShards(clearance: 1.15)
        spawnTimer = 0
        sparkTimer = min(sparkTimer, 0.2)
    }

    private func safestRecoveryAngle() -> CGFloat {
        let candidates = (0..<16).map { normalizedAngle(CGFloat($0) * .pi / 8) }
        let shardAngles = objectLayer.children.compactMap { node -> CGFloat? in
            guard node.lumenObjectKind == .shard else { return nil }
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
            guard node.lumenObjectKind == .shard else { return total }
            guard let objectAngle = storedAngle(for: node) else { return total }
            guard let objectRadius = storedRadius(for: node) else { return total }
            let lanePenalty: CGFloat = objectRadius == radius ? 1 : 0.34
            return total + lanePenalty / max(angularDistance(objectAngle, recoveryAngle), 0.12)
        }
    }

    private func removeNearbyShards(clearance: CGFloat) {
        objectLayer.children.forEach { node in
            guard node.lumenObjectKind == .shard else { return }
            guard let objectAngle = storedAngle(for: node) else { return }
            if angularDistance(objectAngle, angle) < clearance {
                node.removeFromParent()
            }
        }
    }

    private func pulseInvulnerability() {
        player.removeAction(forKey: "invulnerablePulse")
        let pulse = SKAction.sequence([
            .scale(to: 0.86, duration: 0.07),
            .scale(to: 1.06, duration: 0.07)
        ])
        player.run(
            .sequence([
                .repeat(pulse, count: 6),
                .run { [weak self] in
                    guard let self, !self.state.isGameOver else { return }
                    self.player.setScale(1)
                    self.player.alpha = 1
                }
            ]),
            withKey: "invulnerablePulse"
        )
    }

    private func setupShieldAura() {
        shieldAura.strokeColor = state.selectedTheme.shieldColor.withAlphaComponent(0.78)
        shieldAura.fillColor = state.selectedTheme.shieldColor.withAlphaComponent(0.10)
        shieldAura.lineWidth = 2.5
        shieldAura.glowWidth = 12
        shieldAura.zPosition = 4
        shieldAura.alpha = 0
        addChild(shieldAura)
        refreshShieldAura()
    }

    private func refreshShieldAura() {
        shieldAura.strokeColor = state.selectedTheme.shieldColor.withAlphaComponent(0.78)
        shieldAura.fillColor = state.selectedTheme.shieldColor.withAlphaComponent(0.10)
        shieldAura.removeAction(forKey: "shieldPulse")

        guard state.shieldCharges > 0 else {
            shieldAura.run(.fadeOut(withDuration: 0.16))
            return
        }

        shieldAura.alpha = 1
        let scale = 1.0 + CGFloat(min(state.shieldCharges, 3) - 1) * 0.08
        shieldAura.setScale(scale)
        let pulse = SKAction.sequence([
            .group([.scale(to: scale * 1.08, duration: 0.34), .fadeAlpha(to: 0.62, duration: 0.34)]),
            .group([.scale(to: scale, duration: 0.34), .fadeAlpha(to: 1.0, duration: 0.34)])
        ])
        shieldAura.run(.repeatForever(pulse), withKey: "shieldPulse")
    }

    private func flash(color: SKColor) {
        guard elapsedTime - lastScreenFlashTime > 0.12 else { return }
        lastScreenFlashTime = elapsedTime
        let node = SKShapeNode(rectOf: size)
        node.position = center
        node.fillColor = color
        node.strokeColor = .clear
        node.zPosition = 20
        addChild(node)
        node.run(.sequence([.fadeOut(withDuration: 0.16), .removeFromParent()]))
    }

    private func throttledFeverFlash(color: SKColor) {
        guard elapsedTime - lastFeverFlashTime > 0.18 else { return }
        lastFeverFlashTime = elapsedTime
        flash(color: color)
    }

    private func emitBurst(at position: CGPoint, color: SKColor, count: Int) {
        let effectLimit = state.isFeverActive ? 42 : 56
        guard effectLayer.children.count < effectLimit else {
            return
        }

        let availableSlots = max(0, effectLimit - effectLayer.children.count)
        let cappedCount = min(count, state.isFeverActive ? 5 : 8, availableSlots)

        for index in 0..<cappedCount {
            let mote = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...4.2))
            mote.position = position
            mote.fillColor = color.withAlphaComponent(0.9)
            mote.strokeColor = .white.withAlphaComponent(0.35)
            mote.lineWidth = 1
            mote.glowWidth = state.isFeverActive ? 4 : 4
            mote.zPosition = 12
            effectLayer.addChild(mote)

            let angle = CGFloat(index) / CGFloat(max(count, 1)) * 2 * .pi + CGFloat.random(in: -0.22...0.22)
            let distance = CGFloat.random(in: state.isFeverActive ? 32...64 : 24...54)
            let duration = TimeInterval(CGFloat.random(in: state.isFeverActive ? 0.2...0.34 : 0.28...0.48))
            mote.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration),
                    .fadeOut(withDuration: duration),
                    .scale(to: 0.2, duration: duration)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func triggerFeverBurst() {
        flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.16))
        for radius in orbitRadii {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = state.selectedTheme.feverColor.withAlphaComponent(0.6)
            ring.lineWidth = 2
            ring.glowWidth = 9
            ring.zPosition = 10
            effectLayer.addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.28, duration: 0.36), .fadeOut(withDuration: 0.36)]),
                .removeFromParent()
            ]))
        }

        let label = SKLabelNode(text: "FEVER!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 42
        label.fontColor = state.selectedTheme.feverColor
        label.position = center
        label.zPosition = 30
        label.alpha = 0
        label.setScale(0.4)
        addChild(label)

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.08),
            .scale(to: 1.08, duration: 0.14)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 0.42)
        let disappear = SKAction.group([
            .fadeOut(withDuration: 0.22),
            .scale(to: 1.18, duration: 0.22),
            .moveBy(x: 0, y: 14, duration: 0.22)
        ])
        let seq = SKAction.sequence([appear, settle, hold, disappear, .removeFromParent()])
        label.run(seq)
    }

    private func convertNearbyShardsForFever() {
        var converted = 0
        objectLayer.children.forEach { node in
            guard node.lumenObjectKind == .shard else { return }
            guard converted < 3 else { return }
            guard let objectAngle = storedAngle(for: node) else { return }
            if angularDistance(objectAngle, angle) < 1.1 {
                converted += 1
                emitBurst(at: node.position, color: state.selectedTheme.feverColor, count: 4)
                node.removeFromParent()
            }
        }

        guard converted > 0 else { return }
        for _ in 0..<converted {
            state.collectFeverHit()
        }
        shockwave(at: player.position, color: state.selectedTheme.feverColor, radius: 110)
    }

    private func updatePlayerPosition() {
        player.position = point(on: currentRadius, angle: angle)
        shieldAura.position = player.position
        shieldAura.zRotation = -angle
    }

    private func updateOrbitRadius(delta: TimeInterval) {
        guard currentRadius != targetRadius else { return }

        orbitTransitionElapsed = min(orbitTransitionDuration, orbitTransitionElapsed + delta)
        let progress = CGFloat(orbitTransitionElapsed / orbitTransitionDuration)
        let eased = progress * progress * (3 - 2 * progress)
        currentRadius = orbitStartRadius + (targetRadius - orbitStartRadius) * eased

        if orbitTransitionElapsed >= orbitTransitionDuration {
            currentRadius = targetRadius
        }
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

    private var difficultyProgress: Double {
        min(1, Double(max(state.score - 20, 0)) / 150)
    }

    private func scaledInterval(easy: Double, hard: Double) -> Double {
        easy - (easy - hard) * difficultyProgress
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
        let dynamicTolerance = max(collisionRadiusTolerance, playerRadius + collisionRadius(for: node))
        return abs(objectRadius - currentRadius) <= dynamicTolerance
    }

    private func isTouchingPlayer(_ node: SKNode) -> Bool {
        let combinedRadius = playerRadius + collisionRadius(for: node)
        guard let objectAngle = storedAngle(for: node) else { return false }
        guard let objectRadius = storedRadius(for: node) else { return false }
        let angularReach = combinedRadius / max(objectRadius, 1) + 0.035
        let didReachAngle = sweptAngleDidReach(objectAngle, angularReach: angularReach)
        guard didReachAngle else { return false }

        let radialGap = abs(objectRadius - currentRadius)
        guard radialGap <= combinedRadius else { return false }

        let dx = player.position.x - node.position.x
        let dy = player.position.y - node.position.y
        return dx * dx + dy * dy <= combinedRadius * combinedRadius || didReachAngle
    }

    private func collisionRadius(for node: SKNode) -> CGFloat {
        node.lumenObjectKind?.collisionRadius ?? 12
    }

    private func sweptAngleDidReach(_ objectAngle: CGFloat, angularReach: CGFloat) -> Bool {
        let travel = angularTravelDistance(from: previousAngle, to: angle)
        guard travel > 0 else {
            return angularDistance(angle, objectAngle) <= angularReach
        }

        let distanceFromStart = angularTravelDistance(from: previousAngle, to: objectAngle)
        return distanceFromStart <= travel + angularReach || angularDistance(angle, objectAngle) <= angularReach
    }

    private func angularTravelDistance(from start: CGFloat, to end: CGFloat) -> CGFloat {
        let normalizedStart = normalizedAngle(start)
        let normalizedEnd = normalizedAngle(end)

        if angularSpeed >= 0 {
            let distance = normalizedEnd - normalizedStart
            return distance >= 0 ? distance : distance + 2 * .pi
        }

        let distance = normalizedStart - normalizedEnd
        return distance >= 0 ? distance : distance + 2 * .pi
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

    private func canSpawnThreat(at spawnAngle: CGFloat, on radius: CGFloat, allowParallel: Bool) -> Bool {
        if angularDistance(angle, spawnAngle) < 0.82 {
            return false
        }

        let clearance = state.score < 120 ? 0.62 : 0.48
        return !objectLayer.children.contains { node in
            guard node.lumenObjectKind == .shard else { return false }
            guard let objectAngle = storedAngle(for: node) else { return false }
            guard angularDistance(objectAngle, spawnAngle) < clearance else { return false }
            if allowParallel, let objectRadius = storedRadius(for: node), abs(objectRadius - radius) > collisionRadiusTolerance {
                return false
            }
            return true
        }
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

    private func diamondPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: radius * 0.75, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: -radius * 0.75, y: 0))
        path.closeSubpath()
        return path
    }

    private func hazardShardPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 12
        for index in 0..<points {
            let isSpike = index.isMultiple(of: 2)
            let pointRadius = isSpike ? radius : radius * 0.58
            let angle = CGFloat(index) / CGFloat(points) * 2 * .pi - .pi / 2
            let point = CGPoint(x: cos(angle) * pointRadius, y: sin(angle) * pointRadius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func dangerMarkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let half = size / 2
        path.move(to: CGPoint(x: -half, y: -half))
        path.addLine(to: CGPoint(x: half, y: half))
        path.move(to: CGPoint(x: half, y: -half))
        path.addLine(to: CGPoint(x: -half, y: half))
        return path
    }

    private func polygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<sides {
            let angle = CGFloat(index) / CGFloat(sides) * 2 * .pi + .pi / 6
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func starPath(outerRadius: CGFloat, innerRadius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func shieldPath(radius: CGFloat) -> CGPath {
        // 클래식 방패 모양: 위는 평평하고 아래로 갈수록 좁아지며 뾰족하게 끝남
        let path = CGMutablePath()
        let w = radius
        let top = radius * 0.75
        let shoulder = radius * 0.1
        let tip = -radius * 1.15

        path.move(to: CGPoint(x: -w, y: top))
        path.addLine(to: CGPoint(x: w, y: top))
        // 오른쪽 어깨 → 오른쪽 곡선 → 뾰족한 하단
        path.addLine(to: CGPoint(x: w, y: shoulder))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: tip),
            control: CGPoint(x: w * 0.72, y: tip * 0.55)
        )
        // 뾰족한 하단 → 왼쪽 곡선 → 왼쪽 어깨
        path.addQuadCurve(
            to: CGPoint(x: -w, y: shoulder),
            control: CGPoint(x: -w * 0.72, y: tip * 0.55)
        )
        path.closeSubpath()
        return path
    }

    private func corePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        path.move(to: CGPoint(x: -radius * 1.2, y: 0))
        path.addLine(to: CGPoint(x: radius * 1.2, y: 0))
        path.move(to: CGPoint(x: 0, y: -radius * 1.2))
        path.addLine(to: CGPoint(x: 0, y: radius * 1.2))
        return path
    }

    private func smallCirclePath(radius: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    private func burstPath(outerRadius: CGFloat, innerRadius: CGFloat, points: Int) -> CGPath {
        starPath(outerRadius: outerRadius, innerRadius: innerRadius, points: points)
    }

    private func hourglassPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let width = radius * 0.78
        let top = radius
        let waist = radius * 0.18
        let bottom = -radius

        path.move(to: CGPoint(x: -width, y: top))
        path.addLine(to: CGPoint(x: width, y: top))
        path.addLine(to: CGPoint(x: waist, y: 0))
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.addLine(to: CGPoint(x: -width, y: bottom))
        path.addLine(to: CGPoint(x: -waist, y: 0))
        path.closeSubpath()
        return path
    }

    private func hexPath(radius: CGFloat) -> CGPath {
        polygonPath(radius: radius, sides: 6)
    }

    private func magnetBodyPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let width = radius * 0.82
        let arm = radius * 0.34
        let top = radius * 0.82
        let bottom = -radius * 0.36
        path.move(to: CGPoint(x: -width, y: top))
        path.addLine(to: CGPoint(x: -arm, y: top))
        path.addLine(to: CGPoint(x: -arm, y: bottom))
        path.addQuadCurve(to: CGPoint(x: arm, y: bottom), control: CGPoint(x: 0, y: -radius * 1.1))
        path.addLine(to: CGPoint(x: arm, y: top))
        path.addLine(to: CGPoint(x: width, y: top))
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.addQuadCurve(to: CGPoint(x: -width, y: bottom), control: CGPoint(x: 0, y: -radius * 1.85))
        path.closeSubpath()
        return path
    }

    private func pullArrowPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.04))
        path.addLine(to: CGPoint(x: size * 0.22, y: -size * 0.04))
        path.move(to: CGPoint(x: size * 0.06, y: -size * 0.24))
        path.addLine(to: CGPoint(x: size * 0.28, y: -size * 0.04))
        path.addLine(to: CGPoint(x: size * 0.06, y: size * 0.16))
        return path
    }

    private func clearSlashPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.32))
        path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.32))
        return path
    }

    private func lightningPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size * 0.08, y: size * 0.5))
        path.addLine(to: CGPoint(x: -size * 0.36, y: -size * 0.05))
        path.addLine(to: CGPoint(x: -size * 0.04, y: -size * 0.05))
        path.addLine(to: CGPoint(x: -size * 0.18, y: -size * 0.5))
        path.addLine(to: CGPoint(x: size * 0.36, y: size * 0.08))
        path.addLine(to: CGPoint(x: size * 0.04, y: size * 0.08))
        path.closeSubpath()
        return path
    }

    private func checkPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size * 0.42, y: -size * 0.02))
        path.addLine(to: CGPoint(x: -size * 0.12, y: -size * 0.32))
        path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.28))
        return path
    }

    private func addSymbol(to node: SKShapeNode, path: CGPath, color: SKColor, lineWidth: CGFloat) {
        let symbol = SKShapeNode(path: path)
        symbol.fillColor = color
        symbol.strokeColor = color
        symbol.lineWidth = lineWidth
        symbol.glowWidth = 0
        symbol.zPosition = 1
        node.addChild(symbol)
    }

    private func addHourglassSand(to node: SKShapeNode, radius: CGFloat) {
        let sandRadius = radius * 0.22
        let offset = radius * 0.4
        let top = SKShapeNode(path: smallCirclePath(radius: sandRadius))
        top.position = CGPoint(x: 0, y: offset)
        top.fillColor = .white.withAlphaComponent(0.86)
        top.strokeColor = .clear
        top.zPosition = 1
        node.addChild(top)

        let bottom = SKShapeNode(path: smallCirclePath(radius: sandRadius))
        bottom.position = CGPoint(x: 0, y: -offset)
        bottom.fillColor = .white.withAlphaComponent(0.86)
        bottom.strokeColor = .clear
        bottom.zPosition = 1
        node.addChild(bottom)
    }

    private func objectColor(for kind: LumenObjectKind) -> SKColor {
        kind.sceneColor(for: state.selectedTheme)
    }

    private func playerPath(for skin: CoreSkin) -> CGPath {
        switch skin {
        case .orb:
            return CGPath(
                ellipseIn: CGRect(x: -playerRadius, y: -playerRadius, width: playerRadius * 2, height: playerRadius * 2),
                transform: nil
            )
        case .prism:
            return diamondPath(radius: playerRadius * 1.2)
        case .pulse:
            return corePath(radius: playerRadius * 1.12)
        }
    }

    private var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
