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
        static let shard = "shard"
        static let spark = "spark"
        static let shield = "shield"
        static let slow = "slow"
        static let surge = "surge"
        static let star = "star"
        static let feverPulse = "feverPulse"
    }

    private let state: GameState
    private let playerRadius: CGFloat = 14
    private let orbitRadii: [CGFloat] = [76, 112, 148]
    private let collisionRadiusTolerance: CGFloat = 9
    private let orbitTransitionDuration: TimeInterval = 0.16
    private var currentRadius: CGFloat = 76
    private var targetRadius: CGFloat = 76
    private var orbitStartRadius: CGFloat = 76
    private var orbitTransitionElapsed: TimeInterval = 0
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
    private var patternTimer: TimeInterval = 0
    private var patternWaveTimer: TimeInterval = 0
    private var patternDuration: TimeInterval = 8.5
    private var patternIndex = 0
    private var patternStep = 0
    private var currentPattern: RunPattern = .flow
    private var lastFeverFlashTime: TimeInterval = -10
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

        difficulty = 1 + min(CGFloat(state.score) * 0.012, 1.45)
        let timeScale: CGFloat = state.slowTimeRemaining > 0 ? 0.62 : 1
        let feverScale: CGFloat = state.isFeverActive ? 2.25 : 1
        angle += angularSpeed * difficulty * timeScale * feverScale * CGFloat(delta)
        updateOrbitRadius(delta: delta)
        spawnTimer += delta
        sparkTimer += delta
        powerUpTimer += delta
        comboTimer += delta
        patternTimer += delta
        patternWaveTimer += delta
        state.tick(delta: delta)

        if comboTimer > max(1.45, 2.4 - Double(state.level) * 0.08) {
            state.breakCombo()
        }

        updateRunPattern()
        updatePatternSpawns()

        if powerUpTimer > max(4.2, 8.2 - Double(state.level) * 0.24) {
            spawnPowerUp()
            powerUpTimer = 0
        }

        updatePlayerPosition()
        checkCollisions()
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
        player.alpha = 0.64
        targetRadius = currentRadius
        player.run(.sequence([.wait(forDuration: safeUntil), .fadeAlpha(to: 1, duration: 0.25)]))

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
        angularSpeed = abs(angularSpeed)
        lastUpdate = 0
        elapsedTime = 0
        safeUntil = 1.6
        invulnerableUntil = 0
        spawnTimer = 0
        sparkTimer = 0
        powerUpTimer = 0
        comboTimer = 0
        patternTimer = 0
        patternWaveTimer = 0
        patternDuration = 8.5
        patternIndex = 0
        patternStep = 0
        currentPattern = .flow
        lastFeverFlashTime = -10
        difficulty = 1
        renderedShieldCharges = -1
        renderedFeverActive = state.isFeverActive

        resetPlayerVisuals(alpha: 1)
        shieldAura.removeAllActions()
        shieldAura.setScale(1)
        shieldAura.alpha = 0
    }

    private func resetPlayerVisuals(alpha: CGFloat) {
        player.removeAllActions()
        player.setScale(1)
        player.alpha = alpha
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
            if shape.name == NodeName.spark {
                shape.fillColor = objectColor(for: NodeName.spark)
            } else if shape.name == NodeName.shard {
                shape.fillColor = objectColor(for: NodeName.shard)
            } else if shape.name == NodeName.shield {
                shape.fillColor = objectColor(for: NodeName.shield)
            } else if shape.name == NodeName.slow {
                shape.fillColor = objectColor(for: NodeName.slow)
            } else if shape.name == NodeName.surge {
                shape.fillColor = objectColor(for: NodeName.surge)
            }
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
        patternDuration = max(6.8, 10.5 - Double(state.level) * 0.18)
        telegraphPatternStart(currentPattern)
    }

    private func availablePatternSequence() -> [RunPattern] {
        if state.level < 3 {
            return [.flow, .harvest, .gate]
        }
        if state.level < 7 {
            return [.flow, .gate, .harvest, .switchback]
        }
        return [.gate, .switchback, .harvest, .overdrive]
    }

    private func updatePatternSpawns() {
        guard elapsedTime > safeUntil else { return }

        switch currentPattern {
        case .flow:
            if spawnTimer > max(0.62, 1.42 - Double(state.level) * 0.052) {
                spawnShard()
                spawnTimer = 0
            }
            if elapsedTime > 0.45, sparkTimer > max(0.58, 0.92 - Double(state.level) * 0.018) {
                spawnSpark()
                sparkTimer = 0
            }
        case .gate:
            if spawnTimer > max(1.05, 1.72 - Double(state.level) * 0.045) {
                spawnGateWave()
                spawnTimer = 0
            }
            if sparkTimer > max(0.72, 1.15 - Double(state.level) * 0.02) {
                spawnSpark()
                sparkTimer = 0
            }
        case .switchback:
            if patternWaveTimer > max(0.62, 0.95 - Double(state.level) * 0.022) {
                spawnSwitchbackStep()
                patternWaveTimer = 0
            }
            if sparkTimer > max(0.72, 1.05 - Double(state.level) * 0.018) {
                spawnSpark()
                sparkTimer = 0
            }
        case .harvest:
            if sparkTimer > max(0.34, 0.58 - Double(state.level) * 0.01) {
                spawnSparkTrail()
                sparkTimer = 0
            }
            if spawnTimer > max(1.45, 2.15 - Double(state.level) * 0.04) {
                spawnShard()
                spawnTimer = 0
            }
        case .overdrive:
            if spawnTimer > max(0.5, 0.95 - Double(state.level) * 0.025) {
                spawnShard()
                spawnTimer = 0
            }
            if sparkTimer > max(0.48, 0.78 - Double(state.level) * 0.014) {
                spawnSpark()
                sparkTimer = 0
            }
        }
    }

    private func spawnGateWave() {
        let safeIndex = reachableSafeLaneIndex()
        let waveAngle = nextPlayableSpawnAngle(minLead: 1.06, maxLead: 1.62)
        pulseOrbit(at: orbitRadii[safeIndex], color: state.selectedTheme.shieldColor, duration: 0.48)
        for index in orbitRadii.indices where index != safeIndex {
            spawnShard(on: orbitRadii[index], near: waveAngle + CGFloat.random(in: -0.04...0.04), rewardChance: 0, allowParallel: true)
        }
        spawnSpark(on: orbitRadii[safeIndex], near: waveAngle + CGFloat.random(in: -0.08...0.08))
    }

    private func spawnSwitchbackStep() {
        let laneSequence = [0, 1, 2, 1]
        let laneIndex = laneSequence[patternStep % laneSequence.count]
        let radius = orbitRadii[laneIndex]
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.82, maxLead: 1.42)
        pulseOrbit(at: radius, color: state.selectedTheme.shardColor, duration: 0.32)
        spawnShard(on: radius, near: spawnAngle, rewardChance: patternStep.isMultiple(of: 2) ? 0.45 : 0.18, allowParallel: false)
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

    private func spawnShard() {
        let radius = chooseThreatRadius()
        let spawnAngle = nextThreatSpawnAngle(on: radius, minLead: 0.95, maxLead: 1.78)
        spawnShard(on: radius, near: spawnAngle, rewardChance: 0.58, allowParallel: false)
    }

    private func spawnShard(on radius: CGFloat, near spawnAngle: CGFloat, rewardChance: CGFloat, allowParallel: Bool) {
        guard canSpawnThreat(at: spawnAngle, on: radius, allowParallel: allowParallel) else { return }

        let node = SKShapeNode(path: hazardShardPath(radius: 14.5))
        node.name = NodeName.shard
        node.position = point(on: radius, angle: spawnAngle)
        node.zRotation = CGFloat.random(in: 0...(2 * .pi))
        node.fillColor = objectColor(for: NodeName.shard)
        node.strokeColor = objectColor(for: NodeName.shard).withAlphaComponent(0.95)
        node.lineWidth = 2
        node.glowWidth = 9
        node.userData = ["radius": radius, "angle": spawnAngle]
        addSymbol(to: node, path: dangerMarkPath(size: 15.5), color: .black.withAlphaComponent(0.66), lineWidth: 2.4)
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
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.24, names: [NodeName.spark]) else { return }

        let node = SKShapeNode(path: starPath(outerRadius: 10, innerRadius: 4.2, points: 5))
        node.name = NodeName.spark
        node.position = point(on: radius, angle: spawnAngle)
        node.fillColor = objectColor(for: NodeName.spark)
        node.strokeColor = SKColor(red: 1.0, green: 0.98, blue: 0.46, alpha: 0.95)
        node.lineWidth = 1.6
        node.glowWidth = 8
        node.userData = ["radius": radius, "angle": spawnAngle]
        addSymbol(to: node, path: smallCirclePath(radius: 2.8), color: .white.withAlphaComponent(0.76), lineWidth: 1.2)
        objectLayer.addChild(node)
        let pulse = SKAction.sequence([.scale(to: 1.16, duration: 0.35), .scale(to: 1.0, duration: 0.35)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.2), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    private func spawnPowerUp() {
        let radius = randomOrbitRadius()
        let spawnAngle = nextPlayableSpawnAngle(minLead: 1.05, maxLead: 2.4)
        guard !hasNearbyObject(at: spawnAngle, clearance: 0.34, names: [NodeName.shard, NodeName.shield, NodeName.slow, NodeName.surge]) else { return }

        let roll = CGFloat.random(in: 0...1)
        let isSurge = state.level >= 3 && roll < 0.24
        let isShield = !isSurge && (state.shieldCharges == 0 || roll < 0.62)
        let node: SKShapeNode

        if isSurge {
            node = SKShapeNode(path: hexPath(radius: 12.5))
            node.name = NodeName.surge
            node.fillColor = objectColor(for: NodeName.surge)
            addSymbol(to: node, path: lightningPath(size: 14.5), color: .white.withAlphaComponent(0.9), lineWidth: 2)
        } else if isShield {
            node = SKShapeNode(path: shieldPath(radius: 12.5))
            node.name = NodeName.shield
            node.fillColor = objectColor(for: NodeName.shield)
            addSymbol(to: node, path: checkPath(size: 14), color: .white.withAlphaComponent(0.92), lineWidth: 2.2)
        } else {
            node = SKShapeNode(path: hourglassPath(radius: 12.5))
            node.name = NodeName.slow
            node.fillColor = objectColor(for: NodeName.slow)
            addHourglassSand(to: node, radius: 12.5)
        }

        node.position = point(on: radius, angle: spawnAngle)
        node.strokeColor = node.fillColor.withAlphaComponent(0.98)
        node.lineWidth = 1.8
        node.glowWidth = isSurge ? 9 : 7
        node.userData = ["radius": radius, "angle": spawnAngle]
        objectLayer.addChild(node)

        let pulse = SKAction.sequence([.scale(to: 1.12, duration: 0.4), .scale(to: 0.96, duration: 0.4)])
        node.run(.repeatForever(pulse))
        node.run(.sequence([.wait(forDuration: 5.8), .fadeOut(withDuration: 0.22), .removeFromParent()]))
    }

    private func checkCollisions() {
        for node in objectLayer.children {
            guard isOnCollidingRadius(with: node) else { continue }
            guard isTouchingPlayer(node) else { continue }

            if node.name == NodeName.spark {
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
            } else if node.name == NodeName.shield {
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
            } else if node.name == NodeName.slow {
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
            } else if node.name == NodeName.surge {
                let hitPoint = node.position
                node.removeFromParent()
                comboTimer = 0
                state.collectSurge()
                if state.isFeverActive {
                    state.collectFeverHit()
                }
                Haptics.collect(enabled: state.isHapticsEnabled)
                emitBurst(at: hitPoint, color: objectColor(for: NodeName.surge), count: state.isFeverActive ? 10 : 18)
                flash(color: objectColor(for: NodeName.surge).withAlphaComponent(0.2))
            } else if node.name == NodeName.shard {
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
                        .group([
                            .scale(to: 0.1, duration: 0.16),
                            .fadeAlpha(to: 0.35, duration: 0.16)
                        ]),
                        .run { [weak self] in
                            self?.resetPlayerVisuals(alpha: 0.35)
                        }
                    ]),
                    withKey: "deathPulse"
                )
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
        if state.isFeverActive, effectLayer.children.count > 70 {
            return
        }

        for index in 0..<count {
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
        flash(color: state.selectedTheme.feverColor.withAlphaComponent(0.22))
        for radius in orbitRadii {
            let ring = SKShapeNode(circleOfRadius: radius)
            ring.position = center
            ring.strokeColor = state.selectedTheme.feverColor.withAlphaComponent(0.6)
            ring.lineWidth = 3
            ring.glowWidth = 16
            ring.zPosition = 10
            effectLayer.addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.45, duration: 0.52), .fadeOut(withDuration: 0.52)]),
                .removeFromParent()
            ]))
        }

        // FEVER! 텍스트
        let label = SKLabelNode(text: "FEVER!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 52
        label.fontColor = state.selectedTheme.feverColor
        label.position = center
        label.zPosition = 30
        label.alpha = 0
        label.setScale(0.4)
        addChild(label)

        // 그림자용 복사본
        let shadow = SKLabelNode(text: "FEVER!")
        shadow.fontName = "AvenirNext-Heavy"
        shadow.fontSize = 52
        shadow.fontColor = state.selectedTheme.feverColor.withAlphaComponent(0.35)
        shadow.position = CGPoint(x: center.x + 2, y: center.y - 3)
        shadow.zPosition = 29
        shadow.alpha = 0
        shadow.setScale(0.4)
        addChild(shadow)

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.08),
            .scale(to: 1.15, duration: 0.18)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 0.55)
        let disappear = SKAction.group([
            .fadeOut(withDuration: 0.3),
            .scale(to: 1.3, duration: 0.3),
            .moveBy(x: 0, y: 18, duration: 0.3)
        ])
        let seq = SKAction.sequence([appear, settle, hold, disappear, .removeFromParent()])
        label.run(seq)
        shadow.run(seq)
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

    private func isTouchingPlayer(_ node: SKNode) -> Bool {
        let distance = hypot(player.position.x - node.position.x, player.position.y - node.position.y)
        return distance <= playerRadius + collisionRadius(for: node)
    }

    private func collisionRadius(for node: SKNode) -> CGFloat {
        switch node.name {
        case NodeName.shard:
            11
        case NodeName.spark:
            8.5
        case NodeName.shield:
            11.5
        case NodeName.slow:
            11
        case NodeName.surge:
            11.5
        default:
            12
        }
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

        let clearance = state.level < 6 ? 0.58 : 0.46
        return !objectLayer.children.contains { node in
            guard node.name == NodeName.shard else { return false }
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

    private func objectColor(for name: String) -> SKColor {
        switch name {
        case NodeName.spark:
            return SKColor(red: 1.0, green: 0.84, blue: 0.10, alpha: 1)
        case NodeName.shard:
            return state.selectedTheme.shardColor
        case NodeName.shield:
            return state.selectedTheme.shieldColor
        case NodeName.slow:
            return SKColor(red: 0.68, green: 0.32, blue: 1.0, alpha: 1)
        case NodeName.surge:
            return SKColor(red: 1.0, green: 0.46, blue: 0.12, alpha: 1)
        default:
            return .white
        }
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
