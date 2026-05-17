# Lumen Run QA Checklist

Use this checklist before important commits, TestFlight builds, and App Store release candidates.

## Launch
- App launches on the latest iOS simulator.
- App launches on a real iPhone.
- Loading screen appears correctly.
- Start screen appears correctly.
- Loading/start logo reads as a Lumen core and relay orbit, not as a hazard object.
- App icon, loading logo, and start logo use the same Lumen core/orbit/node identity.
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
- Stage 1 clear happens after a meaningful run segment, not almost immediately.
- Stage clear removes active objects and gives a clear checkpoint feeling.
- Relay card choices appear only after stage clears.
- Relay card choices cannot be accidentally selected by a held gameplay tap when the card screen appears.
- Choosing a relay card resumes the run cleanly into the next stage.
- Relay card rarity badges are readable.
- Risk cards clearly show both the tempting upside and the downside.
- Stage 2 and later routes feel visually or structurally different from stage 1.
- Selected relay cards appear in the HUD as a readable build summary.
- Next-stage route intro appears briefly and does not block controls.

## Beta Device Soak
- A real iPhone can play for 5 minutes without severe stutter.
- Stage 3 can be reached without UI getting stuck.
- Fever, magnet, shield, and relay card selection can all happen in the same run.
- Restarting after a longer run does not leave the player transparent, tiny, or hidden.
- Pause/resume works during stages, after stage clear, and after retry.

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
- App icon remains readable at small Home Screen size.
- No debug-only files are included.
