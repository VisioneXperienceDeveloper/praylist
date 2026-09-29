# Praylist 1.2.3 (7)

2026-09-29 릴리즈 준비 기록. App Store에 공개되는 새 기능은 1.0.0 이후 main에 병합한 변경사항을 기준으로 합니다.

## 버전과 소스

- 앱 버전: `1.2.3`, 빌드: `7`
- Bundle ID: `com.visionexperiencedeveloper.praylist`
- App Store 앱 ID: `6810881384`
- 검증 대상 main: `2a97d54bd389207d583b35810c0a964fa5d98f2f`
- 병합 PR: [온보딩 #60](https://github.com/VisioneXperienceDeveloper/praylist/pull/60), [릴리즈 수정 #61](https://github.com/VisioneXperienceDeveloper/praylist/pull/61), [달력 검증 #62](https://github.com/VisioneXperienceDeveloper/praylist/pull/62), [알림 검증 격리 #63](https://github.com/VisioneXperienceDeveloper/praylist/pull/63)
- 릴리즈 브랜치: `release/1.2.3` (main 검증 후 생성)
- Xcode: `27.0 (27A266a)`, iPhone 18 Pro Simulator / iOS 27.0

## 이번 업데이트

- 항목 선택 → 첫 pray 작성 → 알림 설정의 온보딩, 중단 후 이어서 진행
- 언어에 맞춘 추천 항목과 나만의 항목 만들기, 설명 100자 제한
- 시스템·라이트·다크 테마 선택
- 기도손 아이콘과 앱 이름 아래 문구 통일, 불필요한 안내 문구 정리
- 설정 화면의 앱 버전을 실제 빌드 버전과 연결

별도 기능 브랜치의 위젯과 분석 기능은 이번 바이너리에 포함되지 않습니다.

## App Store 제출 문안

- [한국어 업데이트 내용](whats-new.ko.txt)
- [English What's New](whats-new.en-US.txt)
- [App Review Notes](review-notes.en-US.txt)
- Promotional Text (EN): `Start small, keep your prays close, and make a little room for prayer each day.`
- Promotional Text (KO): `작게 시작하고, 나의 pray를 가까이 두며, 매일 기도할 시간을 만들어보세요.`

기존 설명·스크린샷·가격·배포 지역·개인정보 설정을 이어받고 이번 업데이트 내용과 빌드 7을 연결합니다. 로그인이 필요 없는 무료 앱이며, 알림은 선택 사항입니다. 사용자 기록은 기기에 저장됩니다.

## 검증

- 최초 main: 29개 통과, 2개 UI 테스트 실패, 3개 선택 검사 생략.
- 실패 원인: iOS 27 키보드 완료 버튼의 접근성 좌표와 달력 날짜의 Button/Cell 표현 차이. PR #61·#62에서 수정했습니다.
- 수정 main 전체 재검증: 34개 중 31개 통과, 0개 실패, 3개 선택 검사 생략 (iPhone 18 Pro / iOS 27).
- [실제 알림 수신·기도 화면 이동](evidence/reminder-test-summary.json): 1개 통과, 0개 실패. PR #63에서 이전 온보딩 테스트 상태의 영향을 제거했습니다.
- 아카이브를 만든 `fd4deca` 이후 앱 소스와 Xcode 프로젝트에 차이가 없음을 확인했습니다. 후속 변경은 UI 테스트에 한정됩니다.
- [배포 아카이브 검사](evidence/archive-verification.json): PASS.
- [App Store 배포 서명 IPA 검사](evidence/ipa-verification.json): PASS.
- 한·영 213개 문자열 키, App ID·팀·배포 서명, 아이콘, 디버그 전용 데이터 미포함을 확인했습니다.
- IPA SHA-256: `8cfcc2ff86fd08ae294d8bcccb264b21b3d475b67fc726448a0a62323a85d046`

## 업로드 상태

- 2026-09-29 21:57 AEST: Xcode 업로드 성공, Apple 패키지 처리 시작.
- 2026-09-29 22:16 AEST: App Store Connect에서 1.2.3(7)을 심사 제출, 현재 `Waiting for Review`.
- 심사 승인 후 자동 출시 설정을 유지합니다. Apple 심사에는 최대 48시간이 걸릴 수 있습니다.
- App Store Connect 새 버전 `1.2.3` 생성, 한·영 업데이트 내용과 심사 노트 저장 완료.
- 빌드 처리 완료 후 1.2.3(7)에 연결하고 심사 제출을 완료했습니다.
- [App Store Connect 심사 제출 캡처](evidence/app-store-connect-submitted.png)

[App Store Connect](https://appstoreconnect.apple.com/apps/6810881384/distribution)

## 재현 명령

```sh
xcodebuild -project Praylist.xcodeproj -scheme Praylist -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Praylist-1.2.3.xcarchive \
  CODE_SIGNING_ALLOWED=NO PRAYLIST_SUPPORT_URL=https://www.visionexperiencedeveloper.com archive
xcodebuild -exportArchive -archivePath build/Praylist-1.2.3.xcarchive \
  -exportOptionsPlist release/ExportOptions.plist -exportPath build/AppStoreExport-1.2.3 \
  -allowProvisioningUpdates
python3 scripts/verify-archive.py --ipa build/AppStoreExport-1.2.3/Praylist.ipa \
  --version 1.2.3 --build 7 --support-url https://www.visionexperiencedeveloper.com
```

업로드 완료 후에는 같은 버전·빌드를 다시 업로드하지 않습니다. Apple 처리 및 심사 결과는 로컬 빌드 성공과 별도로 기록합니다.
