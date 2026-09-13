# Praylist 1.0 출시 준비

확인일: 2026년 9월 11일. 앱 레코드, 한국어·영어 구현, 공개 정책·지원 페이지 및 제출용 이미지·영상이 준비되었습니다. 로컬 산출물과 Apple의 원격 처리 상태를 구분합니다.

## 현재 제출 상태

<!-- RELEASE_STATUS_START -->
App Store Connect 앱 ID **6810881384**, 버전 **1.0.0 (2)**의 심사 제출을 완료했습니다. 제출 상세 화면의 현재 상태는 **Waiting for Review**입니다.

- 제출 시각: **2026년 9월 11일 11:23 AEST** (Apple 화면 분 단위 표시).
- 제출 ID: `b223a2d1-1f58-4b54-b4e7-7943a92ad8ac`.
- [실제 심사 접수 내역](https://appstoreconnect.apple.com/apps/6810881384/distribution/reviewsubmissions/details/b223a2d1-1f58-4b54-b4e7-7943a92ad8ac) · [보관한 제출 확인 기록](qa/app-store-submission.json).
- 배포용 IPA 서명·검증, 업로드, Apple 처리 및 빌드 2 연결: 완료.
- 한국어·영어 각각 스크린샷 8장과 App Preview 1개 업로드: 완료.
- 가격·배포: 175개 국가·지역 모두 무료, 신규 국가 자동 포함. 승인 후 자동 출시.
- 개인정보 표시: **Data Not Collected**, 게시 완료. 연령 등급 4+.

Apple의 심사 승인과 실제 공개 출시는 아직 대기 중입니다.
<!-- RELEASE_STATUS_END -->

## 앱 및 출시 선택

| 항목 | 현재 값 |
| --- | --- |
| App Store Connect | [Praylist 앱 6810881384](https://appstoreconnect.apple.com/apps/6810881384/distribution/ios/version/inflight) |
| 한국어 이름 | Praylist: 매일 쓰는 pray 노트 |
| 영어 이름 | Praylist: Daily pray journal |
| 기본 스토어 언어 | English |
| 카테고리 | Lifestyle / Productivity |
| 연령 등급 | 4+ |
| Bundle ID | `com.visionexperiencedeveloper.praylist` |
| 지원 환경 | Swift 6, iOS 18 이상, iPhone 세로 화면 |
| 앱 언어 | 한국어·영어, 앱 내 직접 선택 및 기기 지역 기반 자동 선택 |
| 운영자·공개 지원 | VXDeveloper · visionexperiencedeveloper@gmail.com |
| 사용자 확정 출시 선택 | 무료 · 가능한 모든 국가 |

리뷰 담당자의 개인정보는 내부 제출 설정에서만 관리하며 이 문서나 공개 페이지에 기재하지 않습니다. 175개 국가·지역의 무료 가격과 출시 시 제공 상태를 원격 저장 후 확인했습니다. iPhone용으로 제출했으며 Mac 및 Apple Vision Pro 제공은 해제했습니다.

## 공개 정책·지원 페이지

사용자가 확정한 최종 공개 주소는 기존 VXD 도메인의 다음 네 페이지입니다. 로그인 없이 HTTP 200으로 열리고 각 언어의 페이지 제목을 확인했습니다.

- [한국어 개인정보 처리방침](https://www.visionexperiencedeveloper.com/ko/policies/praylist)
- [English Privacy Policy](https://www.visionexperiencedeveloper.com/en/policies/praylist)
- [한국어 지원](https://www.visionexperiencedeveloper.com/ko/supports/praylist)
- [English Support](https://www.visionexperiencedeveloper.com/en/supports/praylist)

앱의 `PRAYLIST_SUPPORT_URL`에는 `https://www.visionexperiencedeveloper.com`을 사용합니다. `PublicPages`가 앱 언어에 맞춰 `/ko` 또는 `/en`과 `/supports/praylist`, `/policies/praylist`를 조합합니다. 제출 전에는 공개 문안이 최종 `pray` / `prays` 정책·지원 자료와 일치하는지 확인합니다.

별도 Vercel 사이트는 예비 산출물로 남겼습니다. 예비 사이트의 프로덕션 **READY** 증거는 배포 `dpl_A7EwjgG4U2Av8981vugMVRrU5K5k`, 프로젝트 `prj_HuYKmQWNfZB5JyYEXsMjc010rl2C`입니다. 예비 원본은 `release/site/`의 정적 HTML 5개이며 외부 스크립트·분석·웹폰트·앱 서버 코드를 포함하지 않습니다. 이 예비 사이트를 최종 앱·스토어 연결로 사용하지 않습니다. 공개 자료에는 지원 이메일만 사용하며 리뷰 담당자 전화번호나 내부 설정을 포함하지 않습니다.

## 준비된 제출 자료

- [한국어 설명](metadata/ko/description.txt) · [영어 설명](metadata/en-US/description.txt). 이름·부제·키워드 등 최종 필드는 `metadata/ko/`, `metadata/en-US/`에 구분해 보관합니다.
- [한국어 정책](privacy.ko.md) · [영어 정책](privacy.en.md) · [개인정보 검토 근거](review/privacy-audit.md)
- [미디어 안내](media-README.md) · [최종 파일 목록·규격·해시](media-manifest.json)
- `store-images/ko/`, `store-images/en/`: 각 8장, 총 16장의 제출용 이미지. 불투명 sRGB PNG, 1320×2868.
- [한국어 App Preview](video/Praylist-App-Preview-ko.mp4) · [영어 App Preview](video/Praylist-App-Preview-en.mp4): 각 28초, 886×1920, H.264 High Level 4.0, 30fps, AAC 48kHz 스테레오 무음 트랙.
- `../Praylist/Resources/Assets.xcassets/AppIcon.appiconset`: 흰 바탕에 검정색 기도하는 손, 1024×1024 불투명 PNG.
- `ExportOptions.plist` 및 `../scripts/archive.sh`: 로컬 서명·내보내기 준비.

이미지와 영상은 격리된 예제 데이터를 표시한 실제 시뮬레이터 화면에서 제작했습니다. 앱 UI를 생성하거나 재구성하지 않았습니다. 최종 업로드에는 `store-images/`와 위 MP4를 사용하고, 원본 캡처·접촉 시트·편집 계획·검증 JSON은 검토 자료로 보관합니다. 현재 미디어 목록의 18개 파일은 실제 크기와 SHA-256 해시가 일치합니다.

## 확인된 검증

- `build/LocalizationFinalQA.xcresult`: 22개 통과, 실패 0. 모델·저장 17개, 현지화 단위 4개, 영어 온보딩·언어 선택 유지 UI 1개.
- `build/MediaScreenshotsKOFinal.xcresult`, `build/MediaScreenshotsENFinal.xcresult`: 언어별 화면 캡처 UI 각 1개 통과.
- `build/ReminderVerified.xcresult`: 실제 반복 로컬 알림 수신 → 알림 탭 → 앱 활성화 → 오늘의 기도 표시 1개 통과. 시뮬레이터에서 수행한 별도 검사이며 실기기 증거는 아닙니다.
- 최종 VXD 정책·지원 페이지 4개 비로그인 HTTP 200 및 언어별 제목 확인. 예비 정적 사이트 5개 페이지의 HTTP 검증은 별도 이력으로 보관합니다.

기능별 증거와 남아 있는 런타임 검증은 [QA 기록](../docs/QA.md)에 정리했습니다. 초기 실패 번들은 수정 이력을 위해 남겨 두며 최신 성공 결과와 혼합하지 않습니다.

## 검증된 배포 빌드와 재현 절차

최종 아카이브는 `build/Praylist-unsigned.xcarchive`, 배포 서명된 제출 IPA는 `build/AppStoreExport/Praylist.ipa`입니다. 아래 명령으로 서명 없는 기기용 아카이브를 만든 뒤 App Store 배포용으로 내보냈습니다. 등록된 개발 기기 없이 배포 인증서와 프로비저닝으로 서명했습니다.

```sh
PRAYLIST_TEAM_ID=JS293ULS3A \
PRAYLIST_BUNDLE_ID=com.visionexperiencedeveloper.praylist \
PRAYLIST_SUPPORT_URL=https://www.visionexperiencedeveloper.com \
./scripts/archive.sh --distribution

python3 scripts/verify-archive.py \
  --archive build/Praylist-unsigned.xcarchive --unsigned \
  --support-url https://www.visionexperiencedeveloper.com
python3 scripts/verify-archive.py \
  --ipa build/AppStoreExport/Praylist.ipa \
  --support-url https://www.visionexperiencedeveloper.com
```

[아카이브 검증](qa/archive-verification-final.json)과 [배포 IPA 검증](qa/ipa-verification-final.json)은 모두 PASS입니다. 180개 한국어·영어 문자열, 최종 VXD 링크, 올바른 App ID·팀·배포 서명, 불투명 아이콘, 디버그 예제 미포함을 확인했습니다.

IPA SHA-256: `68c1a5577ccc4dc0372782784df0bc2ca430e56812119f0229bb48f42ebb9626`.

실제 업로드는 다음 명령으로 완료했으며 결과는 [업로드 확인 기록](qa/app-store-upload-result.txt)에 보관했습니다. 같은 버전·빌드는 다시 업로드하지 않습니다.

```sh
xcodebuild -exportArchive \
  -archivePath build/Praylist-unsigned.xcarchive \
  -exportOptionsPlist release/UploadOptions.plist \
  -exportPath build/AppStoreUpload -allowProvisioningUpdates
```

업로드 성공 시각은 2026-09-11 11:03:59 AEST입니다. Apple 처리 완료 후 빌드 2를 연결하고 Add for Review와 Submit for Review를 실행해 최종 심사 대기를 확인했습니다.

앱은 자체 암호화나 앱 서버 통신 없이 iOS 기본 파일 보호를 사용합니다. `ITSAppUsesNonExemptEncryption=false`, Data Not Collected / Tracking No는 최종 구현·바이너리·원격 답변과 일치합니다.

## 공식 참고

- [Apple App Review](https://developer.apple.com/app-store/review/)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple 스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple App Preview 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications)
- [Apple 로컬 알림 예약](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
