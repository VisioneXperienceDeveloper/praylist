# Issue #45 — Product Analytics Foundation implementation plan

Status: In progress
Updated: 2026-09-24 12:00 Australia/Sydney

## Decision

- Selected phase: Product Foundation (#45)
- Parent branch: `feature/45-product-analytics-foundation`
- Child sequence: #46 taxonomy → #47 abstraction → #48 onboarding funnel → #49 daily prayer funnel
- Why now: Foundation is the first remaining delivery slice in `maintenance-roadmap.md`; activation and prayer events need a stable, private contract before onboarding is changed.
- Provider policy: no remote SDK or transport in this slice. A no-op production client keeps core flows independent; an in-memory recorder is the test seam.

## Product outcome

The app can emit a small, versioned set of useful funnel signals without ever observing or storing prayer content. Analytics can be disabled or unavailable without changing onboarding, prayer persistence, or user-visible behavior.

## Scope

Included:

- Versioned, strongly typed allowlist for onboarding and daily-prayer events
- Provider-neutral client protocol, no-op client, and in-memory test recorder
- Onboarding step signals with per-install idempotency across relaunch
- Daily prayer viewed/started/completed signals and persistence outcome
- Local opt-out setting and privacy tests
- Next phase (#56–#59) implementation plan

Excluded:

- Remote provider, dashboard, widget/revisit/mix events, or retention calculations (#50–#55)
- Onboarding redesign, prayer-time setup, or notification permission UX (#56–#59)
- Prayer title/body, reflection, custom category label, identity, or stable user identifiers

## Privacy and event contract

The serialized event envelope is restricted to taxonomy version, event name, source enum, count, duration bucket, status enum, and timestamp. Optional fields are omitted when not relevant. Unknown event names or fields must fail validation rather than pass through. No free-form strings are accepted.

Daily prayer correlation is ephemeral in-memory context only; it is neither persisted nor added to the event envelope. It cannot contain a Pray/category identifier. Onboarding exactly-once bookkeeping stores only completed event keys in local device preferences, not event payloads. Analytics opt-out is device-local and does not modify `PrayData` or its backup format.

## Delivery sequence and gates

| Stage | Branch | Planned output | Gate before next stage |
| --- | --- | --- | --- |
| #46 Taxonomy | `feature/46-privacy-first-event-taxonomy` | Typed event names, enums, version, privacy contract | Allowlist/encoding tests prove no content or unknown fields can be emitted |
| #47 Abstraction | `feature/47-provider-neutral-analytics` | Client protocol, no-op, validator, in-memory recorder, opt-out | Unit tests prove disabled/no-op/failing consumers never affect core writes |
| #48 Onboarding | `feature/48-onboarding-funnel` | Exactly-once funnel hooks for current onboarding flow | Relaunch and repeated actions do not recount; payloads are content-free |
| #49 Daily prayer | `feature/49-daily-prayer-funnel` | View/start/complete outcome hooks | Save failure is not success; repeated completion is deduplicated; existing prayer suite passes |
| Integration | parent branch | Version bump, docs, full tests, Simulator check | Full XCTest/UI suite and runtime smoke test pass |

Each child gets a focused commit and is merged into the #45 parent only after its gate passes. `main` is not changed or pushed.

## Expected files

- `Praylist/Analytics/AnalyticsEvent.swift`
- `Praylist/Analytics/AnalyticsClient.swift`
- `Praylist/Analytics/AnalyticsSettings.swift`
- `Praylist/App/PraylistApp.swift`
- `Praylist/Views/OnboardingView.swift`
- `Praylist/Views/PrayerView.swift`
- `PraylistTests/AnalyticsTests.swift`
- `PraylistUITests/PraylistUITests.swift` where UI-facing behavior needs coverage
- `docs/analytics-event-taxonomy.md`
- `docs/maintenance-roadmap.md`

Final filenames and boundaries may be adjusted to match the project structure while retaining these contracts.

## Verification plan

- Unit: event allowlist/version/enums, exact envelope keys, invalid names/fields rejected, no content fields possible.
- Unit: no-op and opt-out behavior, recorder acceptance, consumer failure isolation.
- Unit: onboarding event idempotency through relaunch and optional step handling.
- Unit: prayer viewed precedes start; complete success only follows durable `recordPrayer`; write failure emits failure status; duplicate taps do not add duplicate success.
- Regression: `PrayStoreTests`, `LocalizationTests`, and complete XCTest suite.
- Runtime: build/install/launch integrated app in iPhone Simulator; smoke-test existing onboarding and daily-prayer flow. Verify no network permission/SDK and no change to local backup schema.
- Appearance/accessibility: no user-facing UI changes are planned; inspect onboarding and prayer smoke test in Light/Dark and larger text where feasible.

## Definition of done

- #45 and #46–#49 acceptance criteria are met and their Definition of Done checklists are checked only after evidence exists.
- Focused and full tests pass.
- Privacy review confirms payload allowlist and no persistence of event payloads.
- `PrayData` schema/backup bytes remain unchanged.
- App version/build metadata are incremented consistently.
- `main` remains untouched; child commits are integrated on the #45 branch.
- Simulator launches the integrated parent build.
- Roadmap and this plan record dated verification evidence.

## Rollback

Analytics remains an optional dependency with a no-op default. Remove the event hooks or substitute the no-op client without altering the store or existing data. No data migration or external provider state is introduced.

## Verification record

Pending; each stage and final integration result will be recorded here before marking #45 Done.

# Issue #56 — Activation and First Prayer implementation plan

Status: Planned — next delivery phase
Updated: 2026-09-24 12:00 Australia/Sydney

## Decision

- Phase: Activation and First Prayer (#56)
- Child sequence: #57 three-step onboarding → #58 optional Prayer Time → #59 contextual notification permission
- Entry gate: #45–#49 merged and verified on its issue branch
- Why now: activation should build on the versioned event contract and let a person reach the first saved Pray without requiring notification permission.

## Product outcome

A new user can select a category, create and save a first Pray, optionally choose a prayer time, and make an informed notification choice. The required category and first Pray save atomically; skipping time or denying notifications never blocks entry into the app.

## Scope and decisions

- Three explicit steps with localized progress `01 / 03`, `02 / 03`, `03 / 03`.
- Category selection and first Pray are required; Prayer Time and notifications are optional.
- Back navigation preserves entered choices; app relaunch safely resumes or restarts without duplicate first-Pray creation.
- Persist category + first Pray atomically through `PrayStore`; no partially completed onboarding state can mark the user onboarded.
- Prayer Time is device-local, editable later, and interpreted in the current local timezone; timezone changes retain wall-clock preference, while scheduled notifications are recalculated.
- Explain notification value in context, request system permission only after explicit opt-in, and provide Settings recovery after denial/restriction.
- Emit only #46-approved event fields through #47; never send entered Pray title or category text.

Excluded: account creation, cloud sync, required permissions, notification scheduling before explicit opt-in, and redesign of existing daily prayer interaction.

## Delivery sequence and gates

| Stage | Branch | Planned output | Gate before next stage |
| --- | --- | --- | --- |
| #57 3-step onboarding | `feature/57-three-step-onboarding` | Required selection + first Pray, progress/back/resume, atomic commit | Store failure leaves user un-onboarded and data unchanged; localization and UI tests pass |
| #58 Optional Prayer Time | `feature/58-optional-prayer-time` | Localized time picker, skip/edit, timezone behavior | Skip and save paths both complete; settings reflect persisted local time |
| #59 Contextual permission | `feature/59-contextual-notification-permission` | Rationale, explicit request, denied/restricted recovery | Denial/restriction never blocks core use; no prompt before contextual opt-in |
| Integration | parent #56 branch | version bump and end-to-end onboarding | Fresh install, resume, failure, skip, granted/denied paths verified on Simulator |

## Expected files

- `Praylist/Views/OnboardingView.swift`
- `Praylist/Services/PrayStore.swift` and `Praylist/Models/PrayData.swift` only for atomic optional onboarding fields/migration if needed
- `Praylist/Services/ReminderService.swift`
- `Praylist/Views/SettingsView.swift`
- Korean and English `Localizable.strings`
- `PraylistTests/PrayStoreTests.swift`, `LocalizationTests.swift`
- `PraylistUITests/PraylistUITests.swift`

## Acceptance and verification

- Category + first Pray are required, saved atomically, and remain intact after relaunch.
- Prayer Time can be skipped, selected, edited, and remains device-local.
- Permission request follows rationale and an affirmative user action; denied/restricted states remain usable and offer Settings recovery.
- Event analytics obey #46 taxonomy, persist no event payload, and never include user-entered content.
- Test fresh install, each back/forward route, app interruption/relaunch, persistence failure, optional skip, permission grant/deny/restricted, Korean/English, Light/Dark, and larger Dynamic Type on Simulator.
- Run all unit/UI tests and verify current backup fixtures still decode.
- Update roadmap, issue DoD, and app version/build; integrate child commits on the #56 parent branch without modifying `main`.

## Rollback

Keep the current two-step onboarding as a fallback. New optional time/permission preferences must remain separate from `PrayData` unless a versioned migration and backward-compatible backup test are explicitly added.
