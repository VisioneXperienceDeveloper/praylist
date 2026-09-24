# Issue #56 — Activation and First Prayer implementation plan

Status: Planned — next delivery phase
Updated: 2026-09-24 12:26 Australia/Sydney

## Decision

- Phase: Activation and First Prayer (#56)
- Child sequence: #57 three-step onboarding → #58 optional Prayer Time → #59 contextual notification permission
- Entry gate: #45–#49 merged and focused verification passed on its issue branch
- Why now: activation should build on the versioned event contract and let a person reach the first saved Pray without requiring notification permission.

## Product outcome

A new user can select a category, create and save a first Pray, optionally choose a prayer time, and make an informed notification choice. The required category and first Pray save atomically; skipping time or denying notifications never blocks entry into the app.

## Scope and decisions

- Three explicit steps with localized progress `01 / 03`, `02 / 03`, `03 / 03`.
- Category selection and first Pray are required; Prayer Time and notifications are optional.
- Back navigation preserves entered choices; app relaunch safely resumes or restarts without duplicate first-Pray creation.
- Persist category + first Pray atomically through `PrayStore`; no partially completed onboarding state can mark the user onboarded.
- Prayer Time is device-local, editable later, and interpreted in the current local timezone; timezone changes retain wall-clock preference while scheduled notifications are recalculated.
- Explain notification value in context, request system permission only after explicit opt-in, and provide Settings recovery after denial/restriction.
- Emit only #46-approved fields through #47; never send entered Pray title or category text.

Excluded: account creation, cloud sync, required permissions, notification scheduling before explicit opt-in, and redesign of existing daily prayer interaction.

## Delivery sequence and gates

| Stage | Branch | Planned output | Gate before next stage |
| --- | --- | --- | --- |
| #57 3-step onboarding | `feature/57-three-step-onboarding` | Required selection + first Pray, progress/back/resume, atomic commit | Store failure leaves user un-onboarded and data unchanged; localization and UI tests pass |
| #58 Optional Prayer Time | `feature/58-optional-prayer-time` | Localized time picker, skip/edit, timezone behavior | Skip and save paths both complete; settings reflect persisted local time |
| #59 Contextual permission | `feature/59-contextual-notification-permission` | Rationale, explicit request, denied/restricted recovery | Denial/restriction never blocks core use; no prompt before contextual opt-in |
| Integration | parent #56 branch | Version bump and end-to-end onboarding | Fresh install, resume, failure, skip, granted/denied paths verified on Simulator |

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
- Analytics obey #46 taxonomy, persist no event payload, and never include user-entered content.
- Test fresh install, each back/forward route, app interruption/relaunch, persistence failure, optional skip, permission grant/deny/restricted, Korean/English, Light/Dark, and larger Dynamic Type on Simulator.
- Run all unit/UI tests and verify current backup fixtures still decode.
- Update roadmap, issue DoD, and app version/build; integrate child commits on the #56 parent branch without modifying `main`.

## Rollback

Keep the current two-step onboarding as a fallback. New optional time/permission preferences must remain separate from `PrayData` unless a versioned migration and backward-compatible backup test are explicitly added.
