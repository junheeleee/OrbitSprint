# Lumen Run QA Checklist

Use this checklist before important commits, TestFlight builds, and App Store release candidates.

## Launch
- App launches on the latest iOS simulator.
- App launches on a real iPhone.
- Loading screen appears correctly.
- Start screen appears correctly.
- Restart after game over works without app relaunch.
- Player appears at normal size and color after restarting from game over.

## Gameplay
- Orbit movement responds immediately.
- Orbit transition animation does not stutter.
- Player starts on the intended inner orbit.
- Three-depth orbit pattern works as intended.
- Collision only triggers on the current orbit layer.
- Respawn does not place the player into immediate repeated collision.
- Game-over shrink animation does not persist into the next run.
- Obstacles do not spawn directly into unavoidable forward collision.
- Fever mode grants invincibility.
- Fever collisions convert into score.
- Shield item visibly protects the player.

## Audio
- Background music plays.
- Fast sci-fi music loop feels energetic.
- Sound effects are distinct for tap, collect, crash, shield, shield break, fever, and failure.
- Mute settings silence all game audio.
- Audio resumes correctly when unmuted.

## Localization
- Korean text appears when device language is Korean.
- English text appears when device language is English.
- Text fits within buttons and panels.
- App display name is localized correctly.

## App Store Readiness
- Bundle identifier is valid.
- Signing team is selected.
- Game Center capability is enabled for release builds.
- Leaderboard id `com.junpacstudio.lumenrun.highscore` exists in App Store Connect.
- Leaderboard button opens the actual high-score leaderboard, not only the generic Game Center playing status.
- Privacy manifest exists.
- App supports required orientation behavior.
- App icon is present.
- No debug-only files are included.
