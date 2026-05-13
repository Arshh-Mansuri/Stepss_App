# StrideTime — iOS app build brief

## What we're building
A self-discipline iOS app for adults that gates distracting apps (Instagram, TikTok, etc.) behind step count. You walk to earn points. You spend points to unlock blocked apps for a fixed time window. No steps, no scroll.

Target user: adults managing their own screen time. iOS only. No sign-up, no backend, no accounts — everything is on-device.

## Core loop
1. User connects Apple Health (read step count) and Screen Time / FamilyControls (gate apps)
2. User picks which apps to gate via FamilyActivityPicker
3. Steps from HealthKit convert to points (default: 100 steps = 1 point, configurable)
4. When user opens a gated app, a custom shield screen appears
5. User can spend points to unlock that app for 15/30/60 minutes
6. After the unlock window expires, the shield comes back

## Tech stack
- SwiftUI (iOS 17+)
- MVVM
- SwiftData for persistence in an App Group container (so extensions can read/write)
- HealthKit for step data (HKObserverQuery + HKAnchoredObjectQuery + background delivery)
- FamilyControls / ManagedSettings / DeviceActivity for app gating
- No third-party dependencies unless absolutely necessary
- No backend, no auth, no analytics SDK in v1

## Xcode targets
1. **StrideTime** (main app)
2. **DeviceActivityMonitorExtension** — schedules shield apply/remove
3. **ShieldConfigurationExtension** — custom shield UI shown over blocked apps
4. **ShieldActionExtension** — handles button taps on the shield (deduct points, schedule unlock)

All targets share an App Group (e.g. `group.com.stridetime.shared`) for the SwiftData store and UserDefaults.

## Data model
<!-- TODO: data model section was truncated in the original message — paste the rest and append here -->
