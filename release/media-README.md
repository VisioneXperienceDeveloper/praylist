# Praylist release media

The deliverables in this directory use actual app screenshots and Simulator screen recordings. No generated or reconstructed app UI is used.

## App Store screenshots

- Upload `store-images/ko/*.png` to the Korean localization, in filename order.
- Upload `store-images/en/*.png` to the English localization, in filename order.
- Each image is an opaque sRGB PNG at **1320 × 2868**, suitable for the 6.9-inch iPhone screenshot slot.
- There are eight images per language. Each shows a full, uncropped app screen with a short localized headline.
- The cream background and forest text use the app’s visual language. There are no price, ranking, testimonial, or other unverifiable claims.
- Contact sheets are for review; they are not App Store upload files.

The sequence covers the notebook, category swipe, daily prayer, answered prays, prayer calendar, reminder, onboarding, and custom categories. All displayed copy uses lowercase `pray` / `prays` for the app’s entries.

Regenerate after replacing the real captures in `release/screenshots/ko` and `release/screenshots/en`:

```sh
swift scripts/generate-store-assets.swift . all
swift scripts/media-audit-text.swift .
```

## App previews

Upload `video/Praylist-App-Preview-ko.mp4` and `video/Praylist-App-Preview-en.mp4` into their matching localizations.

Encoding target: **886 × 1920**, H.264 High profile Level 4.0, 30 fps, opaque YUV 4:2:0; AAC stereo at 48 kHz. Audio is deliberately silent. Videos use the app in portrait orientation and include actual swipe and sheet transitions. No personal user data appears; the app’s isolated preview fixtures supply the sample content.

The source is a recording of the opt-in `PraylistUITests/testCaptureAppPreview` test. `PRAYLIST_CAPTURE_PREVIEW=1` enables capture and `PRAYLIST_CAPTURE_LANGUAGE=ko` or `en` selects its language. The raw recordings stay in `build/media` and are not part of the upload package. The final edit plans in `video/edit-ko.json` and `video/edit-en.json` retain the exact selected source ranges. Original playback speed is preserved; only idle time is removed.

Reproduce the final edits:

```sh
python3 scripts/media-compose-preview.py release/video/edit-ko.json
python3 scripts/media-compose-preview.py release/video/edit-en.json
python3 scripts/media-validate.py
```

Re-encode a chosen continuous section of raw footage:

```sh
scripts/media-build-preview.sh ko build/media/raw-ko.mp4 START_SECONDS DURATION_SECONDS
scripts/media-build-preview.sh en build/media/raw-en.mp4 START_SECONDS DURATION_SECONDS
```

Keep the selected section between 15 and 30 seconds and verify every scene visually. The exported `*-metadata.json` files are ffprobe reports of the actual deliveries. `*-poster.png` shows the default five-second poster frame. Video contact sheets sample the finished clips at four-second intervals.

Apple reference: [App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications).

## Review checklist

- Correct language in both the editorial copy and actual app UI.
- Full-resolution opaque screenshot files, in the intended order.
- No personal information, notification permission dialog, Simulator chrome, launch blank frame, or test runner appears in final videos.
- App video duration, frame size, frame rate, codec, audio track, and file size verified from the finished output.
- Contact sheets and individual large images inspected for clipping and legibility.

See `media-manifest.json` for the exact final file inventory, verification details, and SHA-256 hashes. `media-text-audit.json` records the OCR results for the matching final image files.

## Final verification — 11 September 2026

- Sixteen fresh original Simulator screenshots: eight Korean and eight English, captured after the terminology update.
- Sixteen editorial App Store images regenerated from those originals. The screenshot helper waits for native page animation to settle.
- Apple Vision OCR and visual contact-sheet review checked displayed terminology and line wrapping.
- Both previews are **28.00 seconds**, **886 × 1920**, **30 fps**, H.264 High Level 4.0 at approximately **11 Mbps**, with a stereo AAC track at **48 kHz**. Each file is below 500 MB.
- First and last frames, scene contact sheets, and the default five-second poster frames were inspected. Final clips show the app throughout; no home screen, test runner, or permission dialog is included.
- Actual swipe and sheet animations play at their original speed. No music or narration is added.
- Capture evidence: `build/MediaScreenshotsKOFinal.xcresult`, `build/MediaScreenshotsENFinal.xcresult`, `build/MediaPreviewKO.xcresult`, and `build/MediaPreviewEN.xcresult` — each capture test passed.

Only `store-images/ko/*.png`, `store-images/en/*.png`, and the two `video/Praylist-App-Preview-*.mp4` files are intended for App Store upload. Raw captures, contact sheets, edit plans, JSON audit reports, and scripts are supporting materials.
