# Praylist 1.0 검증 기록

검증일: 2026년 9월 11일. Xcode 26.6, iOS 26.5 SDK, iPhone 17 Pro Max 시뮬레이터를 기준으로 확인했다. 초기 검증에는 iPhone 17 Pro도 사용했다. 실제 사용자 노트 대신 Debug 전용 메모리 예제와 별도의 UI 테스트 저장 공간을 사용했다.

## 현지화 이후 최종 검사

아래 수치는 `xcresulttool get test-results summary`와 테스트 목록을 직접 읽어 확인했다.

| 결과 번들 | 범위 | 결과 |
| --- | --- | --- |
| `build/LocalizationFinalQA.xcresult` | 모델·저장 17개 + 현지화 단위 4개 + 영어 온보딩·언어 변경·재실행 UI 1개 | 22개 통과, 실패 0, 건너뜀 0 |
| `build/MediaScreenshotsKOFinal.xcresult` | 한국어 `testCaptureLocalizedScreenshots` | 1개 통과, 실패 0 |
| `build/MediaScreenshotsENFinal.xcresult` | 영어 `testCaptureLocalizedScreenshots` | 1개 통과, 실패 0 |

모델·저장 검사는 항목당 10개 제한, 입력 길이, 달성일·취소·미래 날짜 거부, 하루 중복 기록과 시간대, 저장·재실행·삭제, 쓰기 실패 롤백, 손상 파일 보존, 백업 검증·복원, 반복 알림 시간, 버튼 글자 불투명도, 기록된 날짜만 달력에 표시되는 것을 포함한다.

현지화 단위 검사는 지역 설정 `KR`과 그 외·알 수 없는 지역의 기본 언어, 직접 선택한 언어의 저장, 사용자 항목·pray·메모 보존, 한국어·영어 문자열 키 대응, 선택한 언어의 알림 문구와 동일한 비공개 알림 경로를 확인한다. UI 검사는 영어 온보딩 후 언어를 바꾸고 재실행해도 선택 언어와 작성 내용이 유지되는 것을 확인한다.

한국어·영어 캡처 검사는 각각 실제 앱에서 노트, 항목 이동, 기도, 응답된 pray, 기도 달력, 알림, 온보딩, 새 항목 화면을 캡처한다. 이 두 결과를 모든 UI 시나리오를 다시 실행한 결과로 해석하지 않는다.

## 실제 알림 수신·탭 검사

`build/ReminderVerified.xcresult`의 `testDeliveredReminderOpensPrayer`는 **1개 통과, 실패 0**이다. 2026-09-11 01:32 AEST에 실제 반복 로컬 알림 도착 → 알림 열기 → 앱 활성화 → 기존 설정 시트 닫힘 → 오늘의 기도 시트 표시를 확인했다. 현지화 이전에 알림 경로 수정본을 대상으로 실행한 별도 시뮬레이터 실수신 증거이며, 현지화 이후에는 위 단위 검사에서 알림 문구와 같은 request ID 사용을 확인했다.

검사는 `PRAYLIST_VERIFY_DELIVERY=1`을 테스트 실행 환경에 지정해야 실행된다. Debug 메모리 예제가 약 1–2분 뒤 시각으로 실제 `UNCalendarNotificationTrigger(repeats: true)`를 예약하고 설정 시트를 열어둔 채 백그라운드로 전환한다. 알림센터의 실제 도착 알림을 열며, 시스템이 ‘열기’ 액션을 보여주면 그 액션을 사용한다. `simctl push` 등 알림 주입을 사용하지 않는다. 기본 테스트 실행에서는 이 시간 소요 검사를 건너뛴다.

[도착한 알림](qa-evidence/notification-center.png)과 [자동으로 열린 기도 화면](qa-evidence/notification-opened-prayer.png)을 보관했다. 앞선 01:12 AEST 배너 증거는 `build/reminder-delivery-banner.png`다. 상태 표시줄의 9:41은 캡처용 표시값이며 실제 검사 시각이 아니다.

알림 클릭 시 종료되던 문제는 UIKit completion을 MainActor에서 실행하도록 수정해 해결했다. 테스트 뒤에는 임시 노트를 복원하고 테스트용 반복 예약을 정리했다. 이 결과는 실제 iPhone의 소리·진동·잠금 상태 또는 완전 종료 상태에서 검증했다는 의미가 아니다.

## 앞선 회귀 검사와 수정 이력

`build/VerifiedQA.xcresult`, `build/CategoryQA.xcresult`, `build/CalendarQA.xcresult`는 초기 온보딩·달성·기도 완료·재실행, 10칸과 스와이프, 행 내 추가·편집·삭제, 빈 이름·설명으로 새 항목 만들기, 날짜 선택 후 달력과 알림 설정 검사의 이력이다.

초기 실행에서 한글 입력 값 재설정, 키보드 닫힘 타이밍, 달력 높이 변화 및 알림 탭 종료를 발견했다. 해당 문제를 수정하고 관련 검사를 다시 실행했다. 실패 결과 번들은 삭제하지 않았으며, 이전 여러 번들의 통과 항목을 합쳐 현재 전체 테스트가 통과했다고 표시하지 않는다. 현재 언어 기능의 최종 성공 기준은 첫 표의 별도 번들이다.

## 이미지·영상과 공개 사이트

최종 제출 파일은 [미디어 안내](../release/media-README.md)와 [미디어 목록](../release/media-manifest.json)에 기록되어 있다. `release/screenshots/ko/`, `release/screenshots/en/`은 실제 앱 원본 캡처이며, 업로드용 파일은 `release/store-images/ko/`, `release/store-images/en/`의 각 8장이다. 총 16장의 이미지가 불투명 sRGB PNG 1320×2868이다.

[한국어 영상](../release/video/Praylist-App-Preview-ko.mp4)과 [영어 영상](../release/video/Praylist-App-Preview-en.mp4)은 각각 28초, 886×1920, H.264 High Level 4.0, 30fps, AAC 48kHz 스테레오 무음 트랙이다. 실제 시뮬레이터 녹화에서 대기 구간만 덜어냈고 UI나 재생 속도를 합성하지 않았다. 현재 manifest의 18개 최종 파일은 존재 여부·크기·SHA-256이 실제 산출물과 일치한다. 원본 캡처나 접촉 시트는 업로드용 파일이 아니다.

앱 아이콘은 흰 바탕에 검정색 기도하는 손을 그린 1024×1024 불투명 PNG다. 최종 에셋과 설치 후 시뮬레이터 홈 화면을 확인한 증거는 [앱 아이콘](qa-evidence/app-icon-home.jpg)이며 원본·프롬프트는 `design/app-icon/`에 있다.

사용자가 확정한 최종 공개 연결은 기존 VXD 도메인의 정책·지원 네 페이지다. 2026-09-11에 각 페이지가 비로그인 HTTP 200이고 해당 언어의 제목을 표시하는 것을 확인했다.

- [한국어 정책](https://www.visionexperiencedeveloper.com/ko/policies/praylist) · [영어 정책](https://www.visionexperiencedeveloper.com/en/policies/praylist)
- [한국어 지원](https://www.visionexperiencedeveloper.com/ko/supports/praylist) · [영어 지원](https://www.visionexperiencedeveloper.com/en/supports/praylist)

별도 Vercel 예비 사이트도 프로덕션 READY 및 정적 HTML 5개 비로그인 HTTP 200을 확인했지만 최종 앱·스토어 연결은 위 VXD 주소를 사용한다. 예비 폴더에는 외부 스크립트·분석·웹폰트·내부 제출 설정이 없다. 이 사실을 VXD 사이트 전체에 대한 기술·개인정보 검증으로 해석하지 않는다. 공개 연락처는 지원 이메일이며 리뷰 담당자 개인 전화번호를 포함하지 않는다. 최종 공개 문안의 `pray` / `prays` 표기와 정책·지원 원문의 일치는 제출 직전 변경분 검토에 포함한다.

HTTP 확인은 브라우저 시각 검증과 구분한다. 앞선 하위 에이전트의 로컬 `file://` 미리보기는 브라우저 URL 정책에 거절되어 시각 검증으로 계산하지 않았다.

## 아직 확인하지 않은 범위

- 실기기의 소리·진동, 잠금·완전 종료 상태에서 알림 열기, 집중 모드와 권한 변경 후 동작.
- iOS 18 실제 런타임, 접근성 최대 글자 크기, VoiceOver 전체 흐름.
- 실제 파일 앱 및 iCloud Drive를 통한 수동 백업 내보내기·복원 전체 흐름. 인코딩·복원·오류 처리는 자동 검사로 확인했다.
- TestFlight를 통한 실제 iPhone 런타임 확인.

최종 `build/Praylist-unsigned.xcarchive`와 배포 서명된 `build/AppStoreExport/Praylist.ipa`를 새로 생성하고 각각 검증했다. 최종 IPA의 App ID·팀·서명·180개 현지화 문자열·VXD 링크·아이콘·디버그 예제 미포함을 확인했다. `build/VXDLinksQA.xcresult`의 현지화·공개 링크 검사 5개도 통과했다.

2026-09-11 11:03:59 AEST에 업로드가 성공했고, Apple 처리 후 빌드 2를 선택했다. 11:23 AEST에 최종 제출했으며 실제 제출 상세 화면에서 **Waiting for Review**를 확인했다. [제출 기록](../release/qa/app-store-submission.json)과 [최종 IPA 검증](../release/qa/ipa-verification-final.json)을 보관했다. Apple 심사 승인·공개 출시와 실기기 QA는 별개다.
