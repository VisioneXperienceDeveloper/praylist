# Praylist Product Roadmap

이 문서는 현재 로컬 우선 SwiftUI 앱을 제품 방향과 GitHub Project backlog로 연결하기 위한 실행 기준이다. 상세 작업은 GitHub Project **VXD's Praylist**와 이슈 #1–#59에 관리한다.

현재 Ready phase의 구현 계획은 [Issue #1 — Daily Prayer Experience](plans/issue-1-daily-prayer-experience.md)에 정리한다.

## Product direction

Praylist는 기도 목록을 단순히 저장하는 앱이 아니라, 오늘의 기도를 시작하고 완료하며 시간이 쌓이는 여정을 부담 없이 보여주는 개인 기도 동반자다. 기본 원칙은 다음과 같다.

- 기도 시작까지의 마찰을 줄이고, 완료를 압박하지 않는다.
- 기록은 로컬 우선으로 보존하고, 위젯은 개인정보를 노출하지 않는다.
- 목록(Praylist)과 시간의 흐름(Prayer Journey)을 분리해 이해하기 쉽게 만든다.
- 오디오, 리마인더, 공유는 핵심 기도 경험을 방해하지 않는 선택 기능으로 둔다.

## Delivery phases

| Phase | GitHub issues | Outcome |
| --- | --- | --- |
| Daily Prayer Experience | #1, #10–#13 | 오늘의 Praylist와 완료 상태가 한눈에 이해된다. |
| Widget Experience | #2, #14–#19 | 개인정보를 보호하는 홈/잠금화면 진입점이 동작한다. |
| Prayer Journey | #3, #20–#24 | 기도 이벤트와 선택적 메모가 시간순 여정을 만든다. |
| Praylist Identity | #4–#5, #25–#31 | 상태·일시정지와 playlist-style 기도 모드가 명확해진다. |
| Reflection & Retention | #6–#7, #32–#37 | 주간·월간 회고와 리듬/마일스톤이 재방문 이유를 만든다. |
| Experience Enhancement | #8, #38–#40 | 오디오와 앱 내 성장 요청을 검증한다. |
| Growth | #9, #41–#44 | 개인정보를 지키는 공유·초대·지원 흐름을 검증한다. |

## Phase: Daily Prayer Experience

Status: Done
Updated: 2026-09-23 12:30 Australia/Sydney

#11 → #10 → #12 → #13 순서로 구현하고 각 단계의 단위/UI/Simulator 게이트를 통과했다. 오늘의 기도는 empty, reading, saving, completed, already-prayed, save-failed 상태를 명시적으로 구분하며, 완료는 atomic write 성공 이후에만 표시한다. 한국어·영어 완료 문구, 같은 날 재진입, 저장 실패 복구, System/Light/Dark 선택과 재실행 유지가 검증됐다. 상세 명령과 결과는 [Issue #1 구현 계획](plans/issue-1-daily-prayer-experience.md)의 Verification record에 기록한다.

The updated delivery order is:

`Foundation → Activation → Daily Prayer → Re-engagement → Journey → Reflection → Growth`

Foundation is now explicit in GitHub issues #45–#55. Activation is represented by #56–#59. These two phases come before adding more surface area because the product must first make the first Prayer easy to start and then make returning Prayer measurable.

## First delivery slice

첫 구현 단위는 analytics 기반(#45–#49), 3단계 온보딩(#56–#59), 그리고 #10, #11, #12, #13이다.

1. 오늘 화면에서 현재 기도와 다음 행동을 즉시 이해할 수 있어야 한다.
2. 기도 전·진행 중·완료 상태를 시각적으로 구분하되 죄책감이나 연속성 압박을 만들지 않는다.
3. 완료 후 메시지는 짧고 조용하며, 다음 기도를 강요하지 않는다.
4. 시스템/라이트/다크 테마에서 동일한 정보 구조와 충분한 대비를 유지한다.

온보딩의 필수/선택 경계는 다음과 같다.

- Category 선택: Required
- First Pray: Required
- Prayer Time: Optional
- Notifications: Optional

## Measurement contract

Analytics는 privacy-first, provider-neutral 방식으로 구현한다. 이벤트에는 event name, source, count, duration bucket, status, timestamp만 허용하며 다음 콘텐츠는 수집하지 않는다.

- Prayer title/body
- Reflection text
- Custom category name
- Person name
- Answered reflection contents

North Star는 **Weekly Returning Prayer Users**다. 보조 KPI는 Prayer Revisit Rate, Prayer Completion Rate, D7/D30 Prayer Retention, Widget → Prayer Conversion, Answered Reflection Rate로 정의한다. 앱을 열기만 한 행동은 Prayer retention으로 계산하지 않는다.

## Definition of done

- 이슈의 acceptance criteria와 관련 XCTest/UI test가 통과한다.
- 기존 로컬 데이터가 보존되고, 스키마 변경에는 명시적인 backfill 경로가 있다.
- 화면 변경은 iPhone의 라이트·다크·큰 글씨 조건에서 확인한다.
- 위젯·공유·오디오 기능은 개인정보, 권한, 실패 상태를 문서화한다.
- GitHub Project의 Status, Priority, Phase, Sprint, Work Type, Effort가 구현 상태와 일치한다.
