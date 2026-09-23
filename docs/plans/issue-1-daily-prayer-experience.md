# Issue #1 — Daily Prayer Experience implementation plan

Status: Done
Updated: 2026-09-23 12:30 Australia/Sydney

## Implementation result

| Stage | Result | Gate evidence | Next action |
| --- | --- | --- | --- |
| #11 Completion contract | Done | Six explicit session states, five paired Korean/English messages, localization parity and copy-policy tests | Used by #10 and #12 |
| #10 Today's Praylist UX | Done | Snapshot-based paging, empty/revisit/save-failure routes, persistence-gated completion, accessible progress/action labels | Integrated #12 feedback |
| #12 Gentle completion | Done | Approved selector, stable message in session state, success/failure UI tests, no gamification terms | Applied appearance QA |
| #13 Appearance | Done | Automatic/Light/Dark UserDefaults preference, root color-scheme override, relaunch and live system-change UI tests | Completed epic regression pass |

No `PrayData` field or schema version changed. Appearance remains device-local and exported backup bytes are unaffected.

## Decision

- Selected phase: Daily Prayer Experience (#1)
- Project state: Ready
- Why now: Today's Praylist is the product's core `Pray → Repeat` loop and already has a working local-first implementation that can be improved without a data migration.
- First implementation task: #11 completion-state/copy contract, followed immediately by #10's interaction-state implementation.

## Product outcome

A person can open Today's Praylist, understand where they are, move calmly through each category, record the day once, and receive a gentle acknowledgement that is truthful to persistence. The experience must remain useful after today's prayer is already recorded and must not frame prayer as a score or streak.

## Scope

Included:

- Today's Praylist entry, empty, reading, saving, completed, already-prayed, and save-failure states
- Clear current category and progress
- Save-success-gated completion feedback
- Five or more localized completion messages selected once per completed session
- System, Light, and Dark appearance preference
- Dynamic Type, VoiceOver, Reduce Motion, Korean, and English verification
- Test seams for future #49 daily prayer analytics without adding an analytics SDK in this epic

Excluded:

- PrayerEvent/schema v2, timeline, pause/resume, queue, mix, widget, or cloud sync
- Ranking, streak, points, confetti, or spiritual interpretation
- Capturing prayer title/body/note in analytics
- Changing answered-pray lifecycle rules before #25–#27

## Current implementation constraints

- `PrayStore` is the only writer of `PrayData`; writes are validate → encode → atomic file write → memory commit.
- `recordPrayer` already deduplicates by local day. A failed write must not show completion success.
- `PrayerView` currently owns transient `page`, `finished`, and `error` state and renders all non-empty categories.
- `PrayData` schema remains version 1 for this epic.
- Appearance and language preferences are device settings and stay outside exported prayer backup data.
- Existing uncommitted work in shared UI/settings files must be preserved during implementation.

## Delivery sequence

1. #11 — define the state/copy contract.
2. #10 — implement the daily flow and accessibility behavior.
3. #12 — implement localized completion-message selection after a successful save.
4. #13 — apply the appearance preference across the app after the core states are stable.
5. Epic integration pass — run static tests and live Simulator scenarios across the four child issues.

## #11 — Design Prayer Completion States and Messages

### Purpose

Freeze the behavioral and content contract before view implementation changes.

### Why it matters

The UI cannot distinguish truthful completion, repeat entry, and persistence failure without an agreed state model. Copy also needs to remain calm in Korean and English.

### Files to inspect or modify

- `Praylist/Views/PrayerView.swift`
- `Praylist/Resources/ko.lproj/Localizable.strings`
- `Praylist/Resources/en.lproj/Localizable.strings`
- `docs/plans/issue-1-daily-prayer-experience.md`

### Planned output

- State contract: `empty`, `reading`, `saving`, `completed`, `alreadyPrayed`, `saveFailed`
- Five or more paired Korean/English completion messages
- Selection rules: select once after successful persistence; keep stable while completion is visible; do not rotate on body refresh
- VoiceOver announcement order and Reduce Motion behavior
- Error copy that never implies the prayer was recorded when the write failed

### Tests

- Localization-key parity test for every approved message
- Copy-policy test or fixture review preventing empty/duplicate messages

### Live verification

- Read each state in Korean and English on an iPhone Simulator
- Verify completion and error announcements with VoiceOver
- Verify no essential information depends on animation

### Completion criteria

- Product state table and approved bilingual messages are present in the issue
- #10 and #12 can implement without choosing new behavior or copy

### Rollback or adjustment

- Copy changes are isolated to localization resources; the current single completion message remains a safe fallback

## #10 — Improve Today's Praylist UX

### Purpose

Turn the current page counter into a clear, resilient daily prayer session.

### Why it matters

This is the primary action that connects saved Prays to daily return behavior.

### Files to inspect or modify

- `Praylist/Views/PrayerView.swift`
- `Praylist/Views/NotebookView.swift`
- `Praylist/Views/Design.swift`
- `Praylist/Services/PrayStore.swift` only if a small test seam is required
- `PraylistTests/PrayStoreTests.swift`
- `PraylistUITests/PraylistUITests.swift`

### Planned implementation

- Represent the screen with one explicit transient session state instead of independent booleans
- Snapshot eligible categories when a session begins so mid-session view updates do not invalidate the page index
- Preserve the current rule of showing non-empty categories; answered Prays remain visible but are never mutated by prayer completion
- Provide clear first action, category position, previous/next actions, and gentle empty route back to the notebook
- Treat an already-recorded day as a valid revisit: allow reading again without creating a duplicate date
- Disable or serialize the completion action while the atomic write is in flight
- Expose stable accessibility identifiers for state and actions
- Leave a provider-neutral event seam for #49: viewed, started, completed; no SDK or content payload here

### Tests

- Unit: recording twice on the same local day remains idempotent
- Unit: write failure does not mutate `prayerDays`
- UI: empty state, first page, next/previous, final completion, already-prayed re-entry
- UI: large Dynamic Type does not hide the primary action
- UI: VoiceOver labels describe position and action, not only icon names

### Live verification

- Fresh content, one category, multiple categories, answered Pray, already-prayed day, and forced write failure
- Korean/English; Light/Dark; Reduce Motion on/off; accessibility text size
- Close and reopen during reading to confirm no false completion

### Completion criteria

- Every state is reachable and deterministic
- The day is recorded only after the final explicit action and only when persistence succeeds
- No Pray is automatically marked answered
- Existing backup and local file format remain unchanged

### Rollback or adjustment

- Keep the state model view-local and behind `PrayerView`; revert to the current category paging UI without touching stored data

## #12 — Show Gentle Prayer Completion Messages

### Purpose

Provide varied but restrained acknowledgement after a successful daily prayer save.

### Why it matters

Completion should feel remembered while remaining honest about persistence and avoiding gamification.

### Files to inspect or modify

- `Praylist/Views/PrayerView.swift`
- `Praylist/Resources/ko.lproj/Localizable.strings`
- `Praylist/Resources/en.lproj/Localizable.strings`
- `PraylistTests/LocalizationTests.swift`
- `PraylistUITests/PraylistUITests.swift`

### Planned implementation

- Store the selected message in session state only after `recordPrayer` succeeds
- Use a testable selector with at least five approved localized message keys
- Keep the selected message stable until the sheet closes
- Suppress duplicate completion animation and announcement for repeated taps
- Show an actionable error instead of success after a failed write

### Tests

- Unit: selector only returns approved keys and can be deterministic under test
- UI: successful save shows one message; failed save shows no success state
- Localization: all message keys exist in Korean and English

### Live verification

- Complete multiple fresh sessions to sample the message set
- Verify Reduce Motion and VoiceOver behavior
- Verify today's second visit does not append a duplicate prayer day

### Completion criteria

- Success feedback is gated by persistence
- Message remains stable within a visible completion session
- Copy contains no streak, score, rank, or spiritual-outcome claim

### Rollback or adjustment

- Fall back to one approved localized message without changing persistence behavior

## #13 — Add Light, Dark, and System Theme

### Purpose

Let the user choose an appearance while retaining Praylist's paper-and-ink visual identity.

### Why it matters

Prayer often happens in low-light environments, and explicit appearance control improves comfort and accessibility.

### Files to inspect or modify

- `Praylist/App/PraylistApp.swift`
- `Praylist/Views/SettingsView.swift`
- `Praylist/Views/Design.swift`
- `Praylist/Resources/Assets.xcassets/*/*.colorset/Contents.json`
- `Praylist/Resources/ko.lproj/Localizable.strings`
- `Praylist/Resources/en.lproj/Localizable.strings`
- `PraylistTests/LocalizationTests.swift`
- `PraylistUITests/PraylistUITests.swift`

### Planned implementation

- Add `automatic`, `light`, and `dark` device preference under a dedicated UserDefaults key
- Apply `preferredColorScheme` at the app scene boundary
- Keep the preference out of `PrayData` and exported backups
- Audit semantic asset colors, controls, sheets, empty/error/completion states, and iOS 26 glass fallbacks
- Ensure existing language-setting behavior remains independent

### Tests

- Unit: preference persistence and mapping to `ColorScheme?`
- UI: setting survives relaunch and affects core screens
- Static: semantic asset sets contain usable light/dark values and opaque action text

### Live verification

- Change system appearance while Automatic is selected
- Relaunch after selecting Light and Dark
- Inspect notebook, Today's Praylist, completion, settings, alerts, and large text

### Completion criteria

- All three choices behave as named across relaunches
- Core screens retain sufficient contrast and readable hierarchy
- Backup JSON is byte-for-byte unaffected by appearance preference

### Rollback or adjustment

- Default to Automatic and remove the settings row; stored user prayer data remains untouched

## Cross-issue dependencies

- #11 blocks the final copy/state implementation in #10 and #12.
- #10 blocks #12's final integration.
- #13 is technically independent but follows #10/#12 to avoid repeating visual QA.
- #45–#47 and #49 own analytics infrastructure and event delivery. #1 only provides privacy-safe interaction seams.
- #20–#27 own PrayerEvent and lifecycle data. #1 does not introduce schema v2.

## Epic verification plan

### Static verification

- Build the `Praylist` scheme for an iOS 18+ Simulator
- Run `PraylistTests` and focused `PraylistUITests`
- Inspect localization parity and semantic color assets
- Confirm no `PrayData` schema or backup changes

### Live Simulator verification

- Fresh, empty, one-category, multi-category, answered, already-prayed, and forced-save-failure states
- Korean and English
- System, Light, and Dark
- Default and accessibility text sizes
- VoiceOver and Reduce Motion
- Cold launch and same-day re-entry

### Operational safety

- No network, account, or new permission is introduced
- No production deployment or notification schedule mutation is required
- Analytics work remains disabled until its separate privacy-first foundation is implemented

## Verification record

Client: iPhone 16 Simulator, iOS 18.4 (`BB19A214-53D3-4C54-AD0A-6CBFF781E948`).

- `xcodebuild test ... -only-testing:PraylistTests`: 27 tests passed.
- Focused UI suite: normal completion, same-day revisit, empty state, forced write failure, accessibility text size with Reduce Motion, and appearance persistence passed.
- Opt-in live appearance suite: Simulator appearance changed from Light to Dark while the app remained open; Automatic updated and the test passed.
- Regression UI groups: English language persistence, inline Pray editing/deletion, onboarding/achievement/relaunch, categories, reminder settings, notebook paging, and release screenshot routes passed.
- Localization resources retain matching Korean/English key sets. Semantic asset colors have both Light and Dark variants; automated contrast checks meet 4.5:1 for Ink/Paper, Quiet/Paper, and OnAccent/AccentColor.
- XCUI accessibility hierarchy confirms named progress/state/actions; no essential information depends on motion.

The first attempt to run the entire UI target in one invocation stalled while Xcode saved the test record and subsequently stopped the Simulator service. After rebooting the same Simulator, all non-opt-in tests were rerun in focused groups and passed. This was a test-runner infrastructure failure, not an app assertion failure.

## Remaining risk

- Event delivery remains intentionally absent until #49; this epic adds no analytics SDK or private content payload.
- Notification delivery remains an existing opt-in manual test and was not required by the Daily Prayer changes.

## Epic completion criteria

- #10–#13 are complete and their acceptance criteria pass
- The integration matrix passes on a supported iPhone Simulator
- The local-first persistence contract and backup format remain compatible
- Today's Praylist can be used repeatedly without duplicate dates, false success, or accidental answered-state changes
