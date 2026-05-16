# Lumen Run Work Log

## 2026-05-16
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
