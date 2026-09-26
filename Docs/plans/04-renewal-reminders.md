# Phase 4: Renewal Reminders

Flag: `FF_RENEWALS` (Build Settings → Active Compilation Conditions, project level). Remove it to hide the feature.

## What it does
- Local notifications before recurring expenses renew, e.g. "Netflix renews tomorrow · $15.99 · Entertainment".
- They fire at 9 AM, the chosen number of days before the renewal: same day, 1 day or 3 days.
- Tapping a reminder opens that renewal day in the app, through `DeepLink.day`.
- It's opt-in, under **Settings → Notifications → Renewal reminders**, and the setting is per device.

## How it works
- **`Core/Services/RenewalReminders.swift`:**
  - The pure `plan(expenses:now:leadDays:)` covers active, non-one-time expenses. It gets their renewal dates from `ExpenseService.occurrences` over 62 days, which match the calendar and widgets. It drops fire times that have passed, sorts soonest first, and caps at 60 (iOS allows 64 pending notifications).
  - `reschedule()` removes every `renewal-*` request and adds the current plan. If it's called again before finishing, the newest call replaces the running one.
  - It's the `UNUserNotificationCenter` delegate: it shows banners in the foreground and routes taps to `AppCoordinator.handle`.
- **When it reschedules:** `SatoruApp` calls it on `store.expenses` changes (which covers UI, Siri, iCloud and reload), when the app becomes active, and when the currency changes. It's unconditional, so turning the flag off clears reminders scheduled by an earlier build.
- **Storage:** the toggle and lead time live in `.standard` (`renewal_reminders_enabled`, `renewal_lead_days`), not in the synced `AppSettings`. Each device decides for itself.

## Verification
- Tests: `LinguicaSubTrackerTests/RenewalRemindersTests.swift` covers the lead times, skipping one-time/inactive/ended expenses, dropping past fire times, ordering and the cap, and the title wording.
- Simulator: `SIMCTL_CHILD_DEBUG_REMINDERS=1` turns reminders on and fires the first planned reminder 5 seconds later. The "Netflix renews tomorrow · $15.99 · Entertainment" banner was confirmed on the simulator.
- Flag off: the build succeeds and the Settings section is gone.

**Status: implemented.**
