# 데이터와 동작 설계

## 저장 경계

`@MainActor @Observable PrayStore`가 `PrayData`의 유일한 쓰기 소유자다. 변경은 값 복사 → 검증 → JSON 인코딩 → `.atomic` 쓰기 → 메모리 반영 순으로 진행한다. 파일 쓰기가 실패하면 화면 데이터도 바뀌지 않는다. 저장 위치는 `Application Support/Praylist/praylist-v1.json`이며 `completeFileProtectionUntilFirstUserAuthentication`을 사용한다.

손상된 기존 파일은 새 데이터로 덮어쓰지 않고 복구 안내와 원본 내보내기를 제공한다. 스키마 버전 1만 읽으므로 이후 스키마 변경 시 명시적 마이그레이션이 필요하다. 외부 DB나 서버 의존성은 없다.

## 불변 조건

- 온보딩 완료 후 항목은 하나 이상이다.
- 항목별 pray는 응답 여부와 관계없이 최대 10개다.
- 항목과 pray의 UUID는 중복될 수 없다.
- 항목 이름 1–24자, 설명 최대 100자, pray 제목 1–80자, 메모 최대 2,000자다.
- 달성일은 미래일 수 없고, 달성 취소 시 달성일을 제거한다.
- 기도 기록은 현지 날짜의 `yyyy-MM-dd` 키로 중복을 방지한다.
- 외부 JSON 백업은 10MB 이하만 수용하며 같은 불변 조건을 검증한다.

## 언어

`LanguageSettings`는 앱 수준의 Observable 상태이며 선택값을 앱 전용 UserDefaults 키 `praylist.language`로 보관한다. `automatic`, `ko`, `en`을 지원하고, 자동 모드에서는 `Locale.current.region`이 `KR`이면 한국어, 그 외 또는 알 수 없는 지역이면 영어로 결정한다. 이는 iPhone 지역 설정이지 실제 위치가 아니며 GPS 권한이나 네트워크 조회를 사용하지 않는다.

`L10n`은 `ko.lproj`와 `en.lproj`의 문자열을 명시적으로 읽고 날짜·시간 형식을 선택한 언어에 맞춘다. SwiftUI 환경의 locale과 UIKit 기도 달력의 locale도 반영한다. UI는 언어 상태를 관찰하며, 언어 변경 시 로컬 알림의 안내 문구를 다시 예약한다. 앱 활성화 시 지역 설정 변경도 확인한다.

새로 선택하는 기본 항목은 현재 언어로 생성한다. 이미 저장된 항목 이름·설명·pray·메모는 사용자 데이터로 취급해 번역하거나 수정하지 않는다. 언어 선택은 기기별 설정으로 수동 JSON 백업에 포함하지 않는다. 내부 문자열 키와 Swift 식별자는 표시 문구와 구분하고, 사용자에게 보이는 항목 용어는 lowercase `pray` / `prays`로 통일한다.

## 알림과 화면 전환

UserNotifications의 고정 ID `praylist.daily-prayer`와 반복 `UNCalendarNotificationTrigger`를 사용한다. 시·분만 지정해 현지 시각에 반복하며 다시 저장하면 같은 ID가 교체된다. 끄면 대기·전달된 알림을 제거한다. 사용자 조작 시에만 권한을 요청하며, 거부 시 iOS 설정 이동을 제공하고 다른 앱 기능은 제한하지 않는다. 알림은 일반 안내 문구이며 개인 pray 내용과 사용자 데이터를 넣지 않는다.

알림 예약 후 설정 파일 쓰기가 실패하면 이전 예약으로 되돌리는 작업을 시도한다. 백업 복원 시 알림은 꺼진 상태로 복원한다. 집중 모드·시스템 알림 권한·전원·OS 정책에 따른 전달 차이는 앱이 통제하지 않는다.

`UIApplicationDelegateAdaptor`가 앱 시작 단계에서 응답을 받는다. 클릭 의도는 `ReminderService.openPrayer`에 보관하며 노트가 활성화 상태에서 소비한다. 설정·기록·달성일 시트가 열려 있으면 먼저 닫고 `onDismiss`에서 오늘의 기도를 연다. 알림을 여는 것만으로 기도한 날짜를 기록하지는 않는다.

알림 delegate는 completion handler 형태를 사용하고 상태 변경과 completion을 모두 MainActor에서 실행한다. 이전 실수신 검사에서 async delegate의 자동 completion이 백그라운드에서 UIKit 스냅샷을 갱신하다 assertion을 일으켰고 이 방식으로 수정했다. 이후 실제 수신·탭 검사는 통과했다. 상세 증거는 [QA 기록](QA.md)에 있다.

## 화면

네이티브 SwiftUI `TabView(.page)`로 항목을 넘긴다. 행 내부의 TextField와 FocusState로 pray를 작성·편집하며 완료, 포커스 이동, 앱 비활성화 시 저장한다. 새 작성과 제목 편집에는 시트가 없고 달성일 액션만 별도 시트를 사용한다. 상단에는 나의 발자취와 설정, 하단에는 오늘의 기도를 표시한다.

읽기 영역은 종이색으로 유지하고 탐색·주요 액션에 iOS 26의 `GlassEffectContainer`, `glassEffect`, `.glassProminent`를 사용한다. 이전 iOS에서는 기본 머티리얼로 대체한다. `rotation3DEffect`로 책 표지를 넘기는 시작 효과를 제공하며 동작 줄이기에서는 생략한다. 기본 크기는 10칸을 한 화면에 표시하고 큰 접근성 글자나 작은 공간에서는 스크롤을 허용한다.

기도 기록은 UIKit `UICalendarView`를 SwiftUI에 연결한다. 기록된 날에만 초록색 점을 표시하며 월 이동과 날짜 선택은 기본 달력 동작을 사용한다. iPhone 캘린더의 개인 일정을 읽거나 쓰지 않고 캘린더 권한도 필요하지 않다.

## 백업·개인정보·공개 문서

앱에는 계정, 추적, 광고, 분석 SDK 또는 자체 서버 전송이 없다. 내보내기를 실행하면 사용자가 고른 파일 제공자에 평문 JSON을 저장한다. 별도 암호는 설정하지 않는다. iOS 기기 백업은 수동 내보내기와 별개이며, 운영체제 설정에 따라 앱 기록을 포함할 수 있다. 앱 삭제는 외부에 내보낸 파일이나 백업 사본을 삭제하지 않는다.

`PrivacyInfo.xcprivacy`는 추적 없음·수집 없음, 앱 컨테이너 파일 메타데이터 사유 `C617.1`, 사용자가 선택한 백업 파일 사유 `3B52.1`, 앱 언어 선택 저장에 필요한 UserDefaults 사유 `CA92.1`을 선언한다.

`PublicPages`는 Info.plist의 `PraylistSupportURL`을 HTTPS 기본 주소로 확인한다. 최종 기본 주소는 `https://www.visionexperiencedeveloper.com`이며 선택 언어에 따라 `/{ko|en}/supports/praylist`와 `/{ko|en}/policies/praylist`를 구성한다. 앱은 도움말과 정책 전문을 외부 링크로 제공하며 노트 데이터를 자동 첨부하지 않는다.

최종 공개 페이지는 기존 VXD 웹사이트 경로를 사용한다. `release/site/`의 정적 HTML 5개는 별도 예비 산출물이며 최종 앱 링크와 구분한다. 앱의 무수집 설명을 VXD 웹사이트 전체의 호스팅·쿠키 처리에 관한 주장으로 확대하지 않는다. 공개 자료에는 내부 제출 설정이나 리뷰 담당자의 개인정보를 포함하지 않는다. 지원 이메일에 자발적으로 보낸 정보의 처리는 [전체 정책](../release/privacy.ko.md)에 별도로 설명한다.
