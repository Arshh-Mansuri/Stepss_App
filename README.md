# StrideTime

> No steps, no scroll.

A self-discipline iOS app that gates distracting apps behind a step count. Walk to earn points, spend points to unlock blocked apps for a fixed time window. iOS-only, on-device, no accounts.

> The repo and Xcode targets are still named **StepLock** — the StrideTime rename is pending. See [`BRIEF.md`](./BRIEF.md) for the full product spec.

## Status

Early scaffold. Repo currently contains:

- `StepLock/` — main app (SwiftUI, iOS 17+)
- `StepLockShield/` — Shield extension stub
- `Shared/` — SwiftData model and App Group helpers shared by all targets *(not yet wired into Xcode target membership — see [`Shared/README.md`](./Shared/README.md))*

Not yet present: HealthKit pipeline, points ledger, Home / History / Spend / Settings screens, `DeviceActivityMonitorExtension`, `ShieldConfigurationExtension`.

## Architecture

```
┌────────────────────┐   writes earn   ┌──────────────────────┐
│  Main app          │ ──────────────▶ │   SwiftData store    │
│  (HealthKit, UI)   │ ◀────────────── │  (App Group container)│
└────────────────────┘    reads bal    └──────────────────────┘
                                         ▲          ▲
                                         │ reads    │ reads
┌────────────────────────┐               │          │
│  ShieldConfiguration   │ ──────────────┘          │
│  ShieldAction          │                          │
│  DeviceActivityMonitor │ ─────────────────────────┘
└────────────────────────┘
```

- **Persistence:** SwiftData in an App Group container so extensions can read/write the same store.
- **Steps → points:** HealthKit (`HKObserverQuery` + `HKAnchoredObjectQuery` + background delivery) feeds the ledger.
- **Gating:** FamilyControls (`FamilyActivityPicker`, `ManagedSettingsStore`) for shield apply/remove; custom Shield UI; Shield action handler deducts points and creates an `UnlockWindow`.
- **No backend, no auth, no analytics SDK in v1.**

## Targets (planned)

| Target                          | Purpose                                              | Status      |
|---|---|---|
| `StepLock` (→ `StrideTime`)     | Main app                                             | scaffolded  |
| `StepLockShield`                | Shield action extension                              | stub        |
| `DeviceActivityMonitorExtension`| Schedules shield apply/remove on unlock expiry       | not created |
| `ShieldConfigurationExtension`  | Custom shield UI                                     | not created |

All targets share App Group `group.uts.StepLock` (will become `group.com.stridetime.shared` on rename).

## Ownership

| Slice            | Owner   | Scope                                                                                          |
|---|---|---|
| Earning          | Arsh    | HealthKit, points ledger, Home + History screens, milestone notifications                      |
| Gating           | JJ      | FamilyControls auth + picker, all three extensions, App Group plumbing, Apps + Shield UI       |
| Spending         | Aditya  | Spend ledger, unlock scheduler, pricing, Spend + Onboarding + Settings screens, analytics      |

Cross-cutting (data model, App Group identifier, schema versioning, `DayBucket`) lives in `Shared/` and is co-owned.

## Getting started

```sh
git clone https://github.com/Arshh-Mansuri/Stepss_App.git
cd Stepss_App
open StepLock.xcodeproj
```

Requirements: Xcode 15+, iOS 17+ device (FamilyControls and HealthKit don't fully work in the simulator).

After cloning a branch that adds files under `Shared/`, follow the target-membership steps in [`Shared/README.md`](./Shared/README.md) before building.

## Branches

- `main` — integration branch
- `arsh/shared-data-model` — shared SwiftData model and `AppGroup` helpers (this work)

## Tech stack

- SwiftUI · MVVM · iOS 17+
- SwiftData (App Group container)
- HealthKit · FamilyControls · ManagedSettings · DeviceActivity
- Swift Charts (history view)
- No third-party dependencies
