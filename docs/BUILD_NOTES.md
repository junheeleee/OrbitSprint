# Lumen Run Build Notes

Record simulator, device, TestFlight, and App Store build milestones here.

## Build Record Template

```text
Date:
Version:
Build:
Commit:
Device/Simulator:
Result:
Known Issues:
Notes:
```

## 2026-05-16
- Repository standardized as an independent GitHub Desktop project.
- Active project path: `/Users/junheelee/Documents/GitHub/LumenRun/LumenRun.xcodeproj`.
- Current release stage: pre-alpha.
- Added Game Center code integration for high-score leaderboard submission and leaderboard UI.
- Verified `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS' build` succeeds.
- Note: enabling the Game Center entitlement before Apple Developer capability setup caused the provisioning profile error `doesn't include the Game Center capability`. Final release setup must enable Game Center for bundle id `com.junpacstudio.lumenrun` and create leaderboard id `com.junpacstudio.lumenrun.highscore`.
- Device test: Game Center connection succeeded after enabling capability. Leaderboard button opens Game Center but currently only shows the playing status, so the App Store Connect leaderboard still needs to be created/linked.
