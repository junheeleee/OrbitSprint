# Lumen Run Work Log

## 2026-05-17
- Centralized object identity, guide text keys, colors, gameplay sizing, glow, and collision radii in a shared LumenObject catalog.
- Reduced in-run object sizes and updated the object guide to use matching custom silhouettes instead of generic SF Symbol icons.
- Made in-run object silhouettes more explicit: hazards now use spiked shapes with X marks, surge cores show lightning, shields show checks, and slow items show hourglass sand.
- Added an object guide accessible from the start screen, pause screen, and settings help section.
- Strengthened object readability with fixed gold score sparks, blue shield shapes, violet hourglass slow items, and a new orange surge core for high-value scoring.
- Reduced Fever-mode stutter risk by throttling full-screen flashes, lowering burst particle counts, capping fever effect nodes, and spacing rapid score sounds.
- Replaced pattern-name popups with non-text orbit pulse telegraphs so pattern changes feel more integrated into play.
- Added the first pattern-based run pacing system with Sync Flow, Gate Wave, Switchback, Lumen Rush, and Overdrive phases.
- Reprioritized the roadmap around gameplay depth: stage-like pacing, readable obstacle patterns, and strategic risk/reward routes come before additional cosmetic polish.
- Separated reward browsing from the start and post-game screens into a dedicated rewards screen so the main flow stays shorter.
- Restored start-screen scrolling and shortened tutorial/start copy to avoid truncated text.
- Clarified "golden lumen" as glowing lumen sparks in tutorial copy so it still fits alternate themes.
- Hardened the death animation reset so restarting after a crash does not leave the player core as a tiny dot.

## 2026-05-16
- Grouped reward preview cards by reward type so themes and core skins are visually distinct.
- Made unlocked reward preview cards tappable so players can equip themes and core skins directly from the start/post-game screens.
- Added a reward preview showcase on start and post-game screens for locked and unlocked themes/core skins.
- Added unlockable player core skins tied to cumulative daily mission completions.
- Added a dedicated achievements sheet with direct HUD and post-game entry points.
- Clarified the achievements list as an all-achievements view with locked/unlocked status badges.
- Added non-blocking achievement unlock toast feedback during gameplay.
- Fixed the post-game results overlay so it scrolls on smaller device screens.
- Added offline achievements with persistent progress for runs, fever, score milestones, shields, new bests, and daily mission sweep.
- Strengthened the post-game results screen with new-best feedback, run stats, mission completion, and next-theme unlock progress.
- Added offline mission rewards that unlock additional themes after cumulative daily mission completions.
- Added offline daily missions with local progress persistence and Korean/English UI.
- Reduced first-tap stutter risk by prewarming and reusing haptic feedback generators.
- Added a free/offline local records board for top runs and recent runs so progression works before paid App Store Connect/Game Center setup.
- Confirmed Game Center authentication on device; leaderboard still needs App Store Connect configuration to show score rankings.
- Added Game Center code integration for high-score leaderboard authentication, score submission, and leaderboard UI.
- Reviewed App Store completion gaps and added retention/social comparison requirements.
- Fixed a restart regression where the player stayed tiny after the death shrink animation.
- Standardized project management around an independent GitHub Desktop repository.
- Re-rooted `main` so the repository contains the Lumen Run iOS project directly.
- Preserved the old mixed-project history in `backup/monorepo-main-2026-05-16`.
- Added project documentation structure for future requirements, roadmap, decisions, and releases.
