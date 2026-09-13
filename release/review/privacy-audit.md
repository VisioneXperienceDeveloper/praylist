# Praylist privacy audit

Reviewed: September 11, 2026  
Scope: native Praylist iPhone app source and local release policy/support files  
Operator and public contact authorized by the user: VXDeveloper · visionexperiencedeveloper@gmail.com

## App Store Connect answer

The reviewed implementation supports **Data Not Collected** for the app's App Privacy label. It keeps notebook records and preferences on the device and includes no developer server, analytics SDK, advertising SDK, tracking, account system, or automatic upload. This is a source-based assessment, not a statement that App Store Connect has already been configured or that Apple has approved the app.

Apple defines collection for this label in terms of transmitting data off the device so the developer or integrated partners can access it beyond servicing a request in real time. Its additional guidance states that data processed only on the device is not collected for the label. These rules support the answer above even though a user may write personal or sensitive content in a private local pray.

Official source, checked September 11, 2026: [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/) — sections “Data collection,” “Optional disclosure,” “Privacy links,” and the additional guidance for data used only on the device.

The same source requires a publicly accessible privacy-policy URL. The files in `release/site/` are local deliverables; this audit does not establish that a policy has been published.

## Evidence from the application

| Area | Implementation and policy consequence |
| --- | --- |
| Local notebook | `Praylist/Services/PrayStore.swift`: stores `PrayData` at `Application Support/Praylist/praylist-v1.json`, uses atomic writes and `completeFileProtectionUntilFirstUserAuthentication`. No promise of separate app passwords or end-to-end encryption should be added. |
| Stored content | `Praylist/Models/PrayData.swift`: category names/descriptions/symbols/order; pray title/note/creation and achievement dates; prayer day keys; reminder enabled state/time. Model UUIDs identify local records, not a collected account or device identifier. |
| Language | `Praylist/Services/Localization.swift`: reads `Locale.current.region`; automatic resolves `KR` to Korean and other/unknown regions to English. The manual preference is stored in the app's own `UserDefaults`. This is an iPhone Region setting, not GPS, physical location, IP geolocation, or a server request. Existing user content is not automatically translated. |
| Notifications | `Praylist/Services/ReminderService.swift`: asks for alert/sound authorization when enabled and schedules `UNCalendarNotificationTrigger` locally. Notification text is generic, without private pray content. There is no remote push registration or token collection. |
| Notification tap | `Praylist/App/PraylistApp.swift` and `Praylist/Views/NotebookView.swift`: the notification response routes to Today's prayer. Opening it does not itself record prayer completion. |
| Calendar | `Praylist/Views/HistoryView.swift`: `UICalendarView` displays the app's saved prayer days. No EventKit integration or access to the user's Calendar events. |
| Manual export | `Praylist/Views/SettingsView.swift`: `fileExporter` writes a JSON representation of `PrayData`; the user chooses the file destination. No separate password is applied. The language preference is not a field in this manual JSON export. |
| Manual restore | `fileImporter` reads the user-selected security-scoped JSON file, validates it and replaces the current notebook. Restoring disables reminders until the user configures them on the current device. |
| Device backups | The app does not set a backup-exclusion attribute. Data may therefore be included in operating-system device backups according to user settings. Manual JSON exports and device backups must be described separately. No app-operated CloudKit/iCloud synchronization is implemented. |
| Deletion | `deletepray` and category removal delete selected local content. There is no in-app delete-all control or individual prayer-day deletion. Deleting the app removes its local storage; separate exports and backup copies must be managed separately. Do not promise developer-side deletion or recovery of device-only records. |
| Permissions and dependencies | Source/configuration search found no CoreLocation, EventKit, contacts, photos, camera/microphone, AppTrackingTransparency, URLSession, analytics/ad package, CloudKit, remote push, or app-embedded web view. User-selected file access and optional notifications are the relevant app operations. |
| Privacy manifest | `Praylist/Resources/PrivacyInfo.xcprivacy`: tracking false, empty collected-data types and tracking domains. Required-reason entries declare file timestamps (`C617.1`, `3B52.1`) and app-owned UserDefaults (`CA92.1`). Required-reason API declarations are distinct from a claim that personal data is transmitted. |

## Voluntary support contact

The app exposes a support link, not an in-app form that automatically sends notebook data. A user may separately email the support address. The policy therefore describes use of the sender's email address, inquiry, and voluntarily attached files for support, rather than claiming the operator never receives any information under any circumstances.

Apple's optional-disclosure guidance includes infrequent voluntary support requests that satisfy all its criteria. If a future in-app feedback form, log upload, attachment workflow, or ongoing diagnostics service is introduced, reassess the exact data flow and the label; do not assume every support-related collection is exempt.

## Wording boundaries

- Say the app does not transmit private records to developer servers. Do not say data can never leave the device: a user can export it, share it, or enable device backups.
- Do not say there is no information handling at all: support email is voluntary external contact and is covered separately.
- Do not claim the app reads actual location or translates user-authored content when changing languages.
- The policy applies to the app. Hosting access logs, cookies, and any infrastructure policies for the eventual public website have not been audited here. Do not broaden the app's no-collection statement into an unverified site-wide statement.
- Do not invent a fixed support-retention period, legal jurisdiction, hosting provider, or additional policy promise. The English policy translates the reviewed Korean policy, including its existing support-retention statement.

## Local deliverables and reproduction

- `release/privacy.ko.md` and `release/privacy.en.md`: full matching policies.
- `release/support.ko.md` and `release/support.en.md`: support source copy using the app's actual localized labels.
- `release/site/privacy.html`, `privacy-en.html`, `support.html`, and `support-en.html`: standalone pages with Korean/English switching, responsive styling, keyboard focus and skip links, and no JavaScript or external assets.
- Run `python3 scripts/generate-release-site.py` from the repository root after editing Markdown to regenerate the four HTML files. They are intentionally not published by this script.

The authorized clarification in section 5 states that exported JSON files have no separate password. The user's subsequent terminology instruction was applied throughout the policy and support copy: use lowercase pray/prays while preserving the Praylist brand. No app source files were changed by this documentation task.

## Verification

Generated all four pages and parsed their HTML locally. Each page has the correct document language, one page heading, the expected section count (8 policy / 11 support), working relative navigation targets, no unresolved placeholders, and no scripts. The visible main-body text was compared against its Markdown source after normalizing whitespace and Markdown link syntax; all four match exactly.

Browser visual verification was not completed. The in-app browser was unavailable to the sub-agent, and the available browser's URL security policy rejected the local `file://` preview. No alternate path or workaround was attempted after that policy rejection. No site was published and no App Store settings were changed by this task.
