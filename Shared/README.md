# Shared

SwiftData models + utilities used across all four targets:

- `StepLock` (main app — will be renamed `StrideTime`)
- `DeviceActivityMonitorExtension` *(not yet created)*
- `ShieldConfigurationExtension` *(not yet created)*
- `ShieldActionExtension` *(currently `StepLockShield`)*

## Adding to Xcode after pulling

These files are on disk but not yet members of any Xcode target. After `git pull`:

1. In Xcode, right-click the project navigator → **Add Files to "StepLock"…** → select the `Shared/` folder. Choose **Create groups** (not folder references) and **don't** check "Copy items".
2. For each `.swift` file, in the File Inspector → **Target Membership**, check the boxes:

| File | Main app | DeviceActivityMonitor ext | ShieldConfiguration ext | ShieldAction ext |
|---|---|---|---|---|
| `AppGroup.swift`            | ✓ | ✓ | ✓ | ✓ |
| `Schema.swift`              | ✓ | ✓ | ✓ | ✓ |
| `ModelContainerFactory.swift` | ✓ | ✓ | ✓ | ✓ |
| `Wallet.swift`              | ✓ | ✓ | ✓ | ✓ |
| `EarnTransaction.swift`     | ✓ | ✓ | ✓ | ✓ |
| `SpendTransaction.swift`    | ✓ | ✓ | ✓ | ✓ |
| `GatedAppRule.swift`        | ✓ | ✓ | ✓ | ✓ |
| `UnlockWindow.swift`        | ✓ | ✓ | ✓ | ✓ |
| `AppSettings.swift`         | ✓ | ✓ | ✓ | ✓ |
| `DayBucket.swift`           | ✓ | — | — | — |

Models go everywhere because SwiftData needs every target that opens the container to know the schema. `DayBucket` is only used by ledger code.

## App Group entitlement

`AppGroup.identifier` is `group.uts.StepLock` to match what's currently provisioned. On the StrideTime rename, change the constant to `group.com.stridetime.shared` and update both entitlements files.

**Action for JJ:** `StepLockShield/StepLockShield.entitlements` currently has only `family-controls`. Add an `application-groups` array with the same identifier so the extension can open the SwiftData store:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.uts.StepLock</string>
</array>
```

Same goes for the future `DeviceActivityMonitorExtension` and `ShieldConfigurationExtension` targets when they're added.

## Schema version

`AppSchemaV1.version = 1`. Bump and write a migration when shape changes — SwiftData migrations are painful, so keep changes additive when possible.

## Ownership map

| Entity            | Arsh (earn) | JJ (gate)         | Aditya (spend)        |
|---|---|---|---|
| `Wallet`          | write       | read (extension)  | write                 |
| `EarnTransaction` | write       | —                 | —                     |
| `SpendTransaction`| —           | —                 | write                 |
| `GatedAppRule`    | —           | write             | read                  |
| `UnlockWindow`    | —           | read (extension)  | write (on purchase)   |
| `AppSettings`     | read        | read              | write                 |

## Conventions

- `Wallet.balance` is the live source of truth — don't recompute from transactions on the read path. Reconcile on every write.
- All daily-cap logic uses `DayBucket.key(for:)` so earn and spend buckets line up.
- Day rollover is local timezone, not UTC.
- `ApplicationToken` is opaque; only its archived `Data` lives in `GatedAppRule`. JJ's code owns the archive/unarchive helpers.

## Open questions before this is wired in

1. **App Group rename.** Brief calls for `group.com.stridetime.shared`. Decide whether to do it as part of the StrideTime rename or now.
2. **Daily earn cap.** Brief is silent. Suggest 300 points/day default (~30k steps at 100/pt) so it doesn't bind in normal use. Set in onboarding (Aditya's flow).
3. **Pruning.** `EarnTransaction` / `SpendTransaction` will grow forever. Decide pruning policy (e.g., 90-day window) or accept unbounded growth.
4. **Reinstall behavior.** `ApplicationToken`s don't survive reinstalls — the `GatedAppRule` rows will need to be cleared and re-picked. Onboarding needs to handle this.
