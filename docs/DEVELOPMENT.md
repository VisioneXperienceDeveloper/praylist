# Praylist 개발 가이드

pray를 담고, 매일 기도하다. Swift 6와 SwiftUI로 만든 iPhone용 개인 pray 노트입니다. 항목별로 최대 10개의 pray를 정리하고, 기도한 날과 응답된 날짜를 기록합니다.

[English 소개](../README.md) · [한국어 소개](../README.ko.md)

아래 명령은 저장소 루트에서 실행합니다.

## 실행

`Praylist.xcodeproj`를 Xcode 26 이상에서 열고 `Praylist` 스킴과 iPhone 시뮬레이터를 선택합니다. 별도 패키지 설치나 API 키는 필요 없습니다. iOS 18 이상을 지원하며 iOS 26 이상에서는 네이티브 Liquid Glass를 사용합니다.

```sh
open Praylist.xcodeproj
xcodebuild -project Praylist.xcodeproj -scheme Praylist \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' test
```

현재 빌드 설정은 버전 **1.0.0 / 빌드 2**, Bundle ID `com.visionexperiencedeveloper.praylist`입니다. 실기기 빌드에는 해당 앱의 Apple Developer 서명 구성이 필요합니다. 서명·업로드·심사 제출 상태는 [출시 문서](../release/RELEASE.md)에서 별도로 관리합니다.

## 기능

- 두 단계 온보딩: 항목 선택 → 첫 pray 작성
- 항목 이름·설명·상징·순서 관리, 항목당 최대 10개 pray
- 좌우 페이지 스와이프, 빈 줄에서 작성하고 기존 글씨를 눌러 바로 편집
- 달성일 기록·수정·취소와 응답된 pray 모아보기
- 오늘의 기도와 기도한 날에만 표시되는 iOS 기본 달력 UI
- 매일 지정 시각의 로컬 알림, 알림을 누르면 오늘의 기도 화면 열기
- 한국어·영어 지원과 앱 내 언어 선택
- JSON 파일 내보내기·복원, 기기 내 저장
- 밝은/어두운 화면, Dynamic Type, VoiceOver 레이블, 동작 줄이기
- 책 표지를 넘기는 짧은 시작 애니메이션

기본 글자 크기에서는 10칸을 한 화면에 표시합니다. 접근성 글자 크기나 작은 화면에서는 읽을 수 있도록 세로 스크롤을 허용합니다. 응답된 pray도 10개 제한에 포함됩니다. 빈 칸을 눌러 작성하거나 기존 글씨를 눌러 편집한 뒤 키보드의 완료를 누르면 저장됩니다. 제목 작성·편집에는 팝업을 사용하지 않습니다.

## 언어와 데이터

설정 → 언어에서 **지역 설정에 맞춤 / 한국어 / English**를 선택합니다. 자동 선택은 iPhone의 지역 설정이 한국(`KR`)이면 한국어, 그 외 또는 확인할 수 없는 지역이면 영어입니다. GPS나 실제 위치를 사용하지 않습니다. 직접 고른 언어는 재실행 후에도 유지되며, 이미 작성한 pray·항목·메모를 자동 번역하거나 변경하지 않습니다.

앱에는 외부 라이브러리, 로그인, 분석·광고 SDK, 서버 또는 유료 기능이 없습니다. 데이터는 기기에 저장되며 자체 서버 동기화는 제공하지 않습니다. 기기 이전에는 파일 백업을 사용할 수 있습니다. 직접 내보낸 JSON에는 별도 암호가 없고, iOS 설정에 따라 앱 데이터가 기기 백업에도 포함될 수 있습니다. 기도 달력은 iPhone 캘린더 일정에 접근하지 않습니다.

## 구조

- `Praylist/Models`: Codable 값 타입과 백업 스키마 검증
- `Praylist/Services`: 원자적 저장, 로컬 알림, 언어 선택, 공개 정책·지원 링크
- `Praylist/Resources/en.lproj`, `ko.lproj`: 표시 문자열
- `Praylist/Views`: 온보딩, 노트, 달성일, 기도, 기록, 설정
- `PraylistTests`, `PraylistUITests`: 데이터·언어·사용자 흐름과 선택 실행하는 알림·미디어 캡처 검증
- `release`: 한·영 스토어 문안, 정책·지원 문서, 제출용 이미지·영상, 출시 상태

자세한 동작은 [아키텍처](ARCHITECTURE.md), 수행 범위와 증거는 [QA 기록](QA.md)을 참고하세요. 현지화 최종 검증 22개와 한국어·영어 화면 캡처 검사 각 1개가 통과했습니다. 실제 로컬 알림 수신·탭 연결은 별도 시뮬레이터 검사로 확인했으며 실기기 검증은 아직입니다.

## 개발 도구

`ruby scripts/generate-project.rb`로 프로젝트를 다시 생성할 수 있습니다(`xcodeproj` Ruby gem 필요). 일반 빌드에는 Ruby가 필요 없습니다. 프로젝트 설정을 수동 변경했다면 생성 스크립트에도 반영하세요.

아이콘은 흰 바탕의 검정색 기도하는 손입니다. 원본과 생성 프롬프트는 `design/app-icon/`에 있으며, `swift scripts/generate-icon.swift .`로 불투명 1024×1024 PNG를 다시 내보낼 수 있습니다.

Debug에서 `--screenshots`는 메모리 예제를 표시하고, `--uitesting --reset`은 별도의 UI 테스트 노트만 초기화합니다. 테스트·캡처용 언어 설정은 별도 UserDefaults 영역을 사용하며 `--reset-language`로 초기화합니다. Release에는 예제 데이터와 테스트 초기화 경로가 포함되지 않습니다.

실수신 검사 `testDeliveredReminderOpensPrayer`는 테스트 실행 환경에 `PRAYLIST_VERIFY_DELIVERY=1`을 지정해야 실행됩니다. 약 1–2분 뒤 실제 반복 알림을 예약하고, 설정 시트를 열어둔 채 백그라운드로 전환한 다음 알림을 눌러 기도 화면까지 확인합니다. 기본 실행에서는 건너뜁니다.

## 공개 안내와 출시 자료

- [영어 지원](https://www.visionexperiencedeveloper.com/en/supports/praylist) · [한국어 지원](https://www.visionexperiencedeveloper.com/ko/supports/praylist)
- [English Privacy Policy](https://www.visionexperiencedeveloper.com/en/policies/praylist) · [한국어 개인정보 처리방침](https://www.visionexperiencedeveloper.com/ko/policies/praylist)
- [출시 상태와 제출 순서](../release/RELEASE.md)
- [최종 이미지·영상 안내](../release/media-README.md) · [파일·규격·해시 목록](../release/media-manifest.json)

최종 정책·지원 연결은 기존 VXD 도메인의 위 네 페이지입니다. `release/site/`의 정적 HTML 5개는 예비 산출물로 보관합니다. 예비 페이지는 Markdown 수정 후 `python3 scripts/generate-release-site.py`로 재생성할 수 있습니다.
