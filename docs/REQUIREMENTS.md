# Lumen Run Requirements

## Gameplay
- One-button orbit movement should remain responsive and smooth.
- The player should never respawn directly into unavoidable collision.
- Collision should only occur with obstacles on the player's current orbit layer.
- Collision and pickup checks must stay reliable at high speed, including Fever, by accounting for movement between frames.
- Collision reliability fixes should stay lightweight enough to preserve smooth gameplay on device.
- SpriteKit transient effect and object counts should be bounded during long runs and Fever sequences.
- Magnet behavior should move smoothly every frame while keeping affected-object counts capped to preserve smooth play.
- Temporary invulnerability visuals must always restore the player core to full opacity when the effect ends.
- Player-core feedback should avoid opacity animation; respawn and invulnerability should use scale/ring effects so the core never appears unintentionally transparent.
- Obstacles should spawn in ways that preserve player agency.
- The app icon, loading screen, and start screen should use the same core/orbit/shard identity so the game feels like a coherent IP rather than a generic mockup.
- In-game player and orbit visuals should reinforce the same lumen-core and relay-network identity without reducing obstacle readability.
- Difficulty should ramp gradually from score, keeping the opening run approachable before gate, switchback, and overdrive patterns appear.
- Fever should feel faster and rewarding without causing noticeable frame stutter on device.
- Fever mode should make the player invincible, faster, flashier, and able to convert collisions into score.
- The HUD should show fever buildup progress so players can judge when to risk chasing one more spark.
- HUD text for score, best score, combo, and fever status must remain single-line and non-overlapping on small iPhone screens.
- Active power-up timers, especially shield duration, must remain visible while the effect is running.
- Gameplay depth is the current highest product priority before more cosmetic polish.
- Add stage-like pacing with recognizable obstacle patterns, escalation beats, and short relief windows.
- Add strategic decisions inside runs, such as choosing risky score routes, safer survival routes, and timed item pickups.
- Early runs should offer a quick readable reward route within the first moments after spawn safety ends.
- Patterns should create route choices where safer paths give steady sparks and riskier paths offer stronger rewards such as surge cores.
- Fever entry should feel like a payoff moment by converting nearby danger into points and visual impact.
- First pattern set should include readable phases: normal flow, gate waves, switchback pressure, lumen rush, and overdrive.
- Pattern changes should be communicated through spawn layout, orbit pulses, color, and item placement instead of intrusive text banners.
- Run patterns should have distinct reward/risk identities: harvest favors magnets and spark trails, gates offer shield preparation, switchbacks reward bomb timing, and overdrive pushes surge-core risk/reward.
- Collectibles and hazards must be visually distinct by both shape and color, not only by color.
- Object identities: gold sparks build combo, orange surge cores give high-value score, blue shields protect, violet hourglasses slow time, teal magnets pull nearby sparks, green clear bombs remove nearby hazards, magenta shards are hazards.
- Hazard objects should use aggressive shapes and danger marks, such as spikes and X marks, so they read as avoidable threats without relying on color.
- Object guide icons should mirror the in-run silhouettes and markings, not generic system icons, so players build one consistent visual memory.
- Utility objects should use function-first silhouettes, such as magnet bodies and burst shapes, instead of round badges with small symbols.
- Object identity, localization keys, guide colors, gameplay size, glow, line width, and collision radius should be managed from a shared object catalog.
- Provide an object guide from non-gameplay surfaces such as start, pause, and settings; avoid interrupting active runs with explanatory popups.

## Controls
- Current preferred control direction: one-button orbit movement.
- Input should feel immediate without stutter during orbit changes.

## Audio
- Background music should be fast, energetic, and sci-fi themed.
- Sound effects should clearly distinguish collision, item pickup, shield, fever, and scoring.
- Muting from device/app settings should consistently mute game audio.

## UX
- Include a loading screen and start screen.
- Korean and English should be supported.
- Korean App Store users should see Korean by default when device language is Korean.
- Start and post-game screens must remain scrollable on smaller devices.
- The start screen should stay short and focused on starting a run; reward browsing belongs in a separate rewards screen.

## Progression And Retention
- Keep the local best score for offline play.
- Keep a free/offline local records board with recent runs and top runs while App Store Connect/Game Center setup is unavailable.
- Add Game Center leaderboards so players can compare scores with friends and global players.
- Use `com.junpacstudio.lumenrun.highscore` as the initial high-score leaderboard ID.
- Add achievements for first run milestones, fever mastery, shield saves, score thresholds, and daily play streaks.
- Offline achievements should track local progress first, with IDs that can later map to Game Center achievements.
- The achievements list should show both unlocked and locked achievements with clear status and progress.
- Players should be able to open the full achievements list directly from the HUD and post-game screen.
- Achievement unlocks should provide immediate in-run feedback through a short, non-blocking toast.
- Add a clear post-game results screen that shows score, best score, rank/percentile when available, earned achievements, and a strong retry call-to-action.
- Post-game results should highlight new records, mission completion, and progress toward the next unlock.
- Add daily or weekly challenge goals to create reasons to return.
- Daily missions should work offline and rotate by local calendar day.
- Add lightweight unlocks such as themes, player core skins, trail effects, or title badges.
- Theme unlocks should be driven by total completed daily missions and remain available offline.
- Core skin unlocks should be driven by total completed daily missions and change the in-run player shape.
- Locked rewards should be previewable before unlock so players can see future goals and feel motivated to chase them.
- Unlocked rewards should be equipable directly from the dedicated rewards screen without visiting settings.
- Reward previews should be visually grouped by reward type, such as themes and core skins, so players understand multiple cosmetic slots.
- Do not introduce a store until the game has a meaningful earned currency or purchase loop; use rewards for mission-based unlocks first.

## Release Quality
- Maintain App Store readiness: signing, bundle id, privacy manifest, localization, and stable device testing.

## App Store Completion
- Prepare App Store screenshots, preview text, subtitle, keyword set, privacy answers, support URL, and marketing copy.
- Ensure the game works offline, with online features gracefully hidden or delayed when Game Center is unavailable.
- Enable Game Center capability in Apple Developer/App Store Connect before release builds.
