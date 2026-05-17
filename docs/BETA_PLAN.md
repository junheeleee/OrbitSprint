# Lumen Run First Beta Plan

This document defines the target for the first playable beta. The goal is not App Store release yet. The goal is a stable, fun-enough build that can survive repeated device playtests and produce useful feedback.

## Beta Goal
- Keep the core as an endless score run.
- Use stages as longer checkpoints, not separate levels.
- Let stage clears create a clear rhythm: clear objects, show stage clear, choose a relay card, restart the next route.
- Keep early play readable and fair.
- Make cards feel like the beginning of a roguelike deckbuilding layer.
- Prioritize smooth device performance over extra visual noise.

## Beta Readiness Checklist
- [ ] A real iPhone can play for 5 minutes without noticeable frame drops.
- [ ] A real iPhone can reach stage 3 without broken UI, invisible player state, or stuck pause state.
- [ ] Stage 1 feels readable and not too punishing.
- [ ] Stage clear feels like a real checkpoint, not only a pause popup.
- [ ] Card choices do not appear too often.
- [ ] Card choices do not repeat in a boring pattern.
- [ ] Selected cards leave a small visible build summary during the run.
- [ ] New stages show a short route identity cue so observers understand that the route changed.
- [ ] Fever feels powerful but does not cause stutter.
- [ ] Magnet can collect many sparks without frame spikes.
- [ ] Game over, retry, pause, settings, rewards, achievements, and object guide all remain usable.
- [ ] Sound off fully mutes music and effects.
- [ ] Korean and English text fit on small iPhone screens.

## Playtest Script
Run this script on device after every major gameplay/balance commit.

1. Start a fresh run and play until stage 1 clear.
2. Choose each type of relay card across multiple runs when possible.
3. Continue to stage 2 and check whether the route feels distinct from stage 1.
4. Trigger Fever at least once.
5. Pick up magnet twice in one run.
6. Pick up shield and intentionally crash once.
7. Pause and resume during active gameplay.
8. Die, retry, and verify the player core returns to normal size and opacity.
9. Open rewards, achievements, records, settings, and object guide.
10. Play one longer run for at least 5 minutes.

## Known Watch Areas
- Stage target score may still need tuning after real play.
- Relay cards need stronger long-term identity: rarity, levels, risk cards, and build summary.
- Stage themes currently change visual tone and opening route, but later should add clearer stage-specific rules.
- Game Center leaderboard still depends on App Store Connect setup.
- App Store release needs metadata, screenshots, privacy review, and final signing checks.

## Next Beta Work
- Add card rarity and 2-3 risky cards.
- Do a device performance pass after 5-minute runs.
- Prepare TestFlight/App Store Connect checklist once the gameplay loop survives playtesting.
