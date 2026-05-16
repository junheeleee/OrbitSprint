# Lumen Run Requirements

## Gameplay
- One-button orbit movement should remain responsive and smooth.
- The player should never respawn directly into unavoidable collision.
- Collision should only occur with obstacles on the player's current orbit layer.
- Obstacles should spawn in ways that preserve player agency.
- Fever mode should make the player invincible, faster, flashier, and able to convert collisions into score.

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

## Release Quality
- Maintain App Store readiness: signing, bundle id, privacy manifest, localization, and stable device testing.

## App Store Completion
- Prepare App Store screenshots, preview text, subtitle, keyword set, privacy answers, support URL, and marketing copy.
- Ensure the game works offline, with online features gracefully hidden or delayed when Game Center is unavailable.
- Enable Game Center capability in Apple Developer/App Store Connect before release builds.
