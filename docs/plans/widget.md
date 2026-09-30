# 홈 화면 위젯 기획

## 목표

- **Problem:** 오늘의 기도와 새 Pray를 시작하려면 사용자가 앱을 찾아 열어야 하고, Pray 문구가 홈/잠금 화면에 예기치 않게 노출될 수 있다.
- **Target User:** Praylist를 꾸준히 쓰고 빠른 진입을 원하지만 개인 문구 노출은 직접 통제하려는 사용자.
- **Goal:** 오늘 기도 진입, 새 Pray 작성, 선택 Pray, 카테고리 Pray 목록을 홈 화면 위젯으로 제공해 사용자가 원하는 크기와 정보 노출 수준으로 앱에 돌아오게 한다.
- **Success Metric:** 네 목적지(오늘 기도, 새 Pray, 선택 Pray, 카테고리 목록)의 라우팅 검증 4/4가 지정 화면에 도착한다. 새 설치 기본값에서 제목/메모 노출은 0건이며 위젯 진입으로 생성되는 기도 기록은 0건이다.
- **Non-goals:** 잠금 화면/StandBy 위젯, 위젯 내 직접 작성·저장, 잠금 화면 문구 노출 보장, 서버 동기화, 메모 노출, 위젯 탭에 따른 기도/달성 기록 자동 생성.

## 현재 구현

- **현재 구조:** `main`을 기준으로 만든 `feature/home-screen-widgets`에서 `PraylistWidget` 타깃과 App Group을 추가했다. 기존 위젯 브랜치는 백업 후 정리했으며 새 기획의 네 목적지를 `HomeWidgetIntent`로 구성한다.
- **처리 흐름:** 기본 앱의 `PrayStore`가 JSON 파일에 변경을 원자 저장한 뒤 최소 정보를 App Group snapshot에 복사하고 WidgetKit 타임라인을 갱신한다. widget URL은 `WidgetRouter`와 기존 노트 화면에서 처리한다. 위젯 실행은 기도 완료로 기록하지 않는다.
- **사용 기술/구성요소:** SwiftUI, `PrayStore`, `PrayData` schema v1, 로컬 JSON이 현재 앱 구성이다. 계획된 구성은 WidgetKit, App Groups, timeline provider/view/configuration, 앱 URL 라우팅이다. 크기 표기는 실제 systemSmall/systemMedium/systemLarge family에 매핑한다.
- **제약 또는 문제점:** 타임라인 갱신은 즉시 반영을 보장하지 않는다. App Group 접근은 서명/설치 환경 검증이 필요하다. 실제 지원 family는 systemSmall/systemMedium/systemLarge이며 목록 표시 상한은 1/2/6개다. 항목당 Pray 제한은 10개다. 앱에서 제목 공유를 먼저 허용하고 위젯별 제목 표시를 켜야 제목이 보인다. 검증 기록은 [홈 화면 위젯 QA](../qa-widgets.md)에 남긴다.

## 사용자 흐름

1. **진입 →** 사용자가 홈 화면 편집에서 Praylist 위젯을 찾는다. **시스템 반응 →** 오늘 기도, 새 Pray, 선택 Pray, 카테고리 목록 목적지를 지원 family 변형으로 제안한다.
2. **사용자 행동 →** 위젯을 고르고 홈 화면에 배치한다. **시스템 반응 →** 개인 문구 숨김을 기본값으로 둔 설정을 표시하고 필요한 경우 위젯별 카테고리/Pray 선택을 받는다.
3. **사용자 행동 →** 제목 표시를 선택하거나 숨김을 유지한다. **시스템 반응 →** 제목 노출 선택 상태를 저장하고 위젯 타임라인 갱신을 요청한다. 메모는 어떤 모드에서도 노출하지 않는다.
4. **다음 행동 →** 사용자가 위젯의 진입 CTA/Pray/목록을 탭한다. **시스템 반응 →** 오늘 기도, 새 Pray 편집, 선택 Pray, 해당 카테고리 화면으로 라우팅하고 ID/대상을 현재 데이터와 검증한다.
5. **목표 달성 →** 사용자가 앱에서 실제 기도를 완료하거나 새 Pray를 저장한다. **시스템 반응 →** 기존 앱 흐름이 처리하고 성공 저장 후 위젯 snapshot을 갱신한다. 위젯 탭 자체는 Pray 데이터나 기도 날짜를 바꾸지 않는다.

## 규칙과 예외 처리

유형: `BR` 비즈니스 규칙, `VR` 검증 규칙, `AR` 권한 규칙, `SR` 보안 규칙, `ER` 예외 규칙.

| ID | 조건 | 허용/제한 동작 | 예외 발생 시 처리 | 사용자에게 보이는 결과 |
| --- | --- | --- | --- | --- |
| BR-WID-01 | 새 위젯을 구성한다. | 제목/메모 숨김을 기본으로 한다. | 설정이 없거나 디코딩 실패면 숨김으로 처리한다. | 개인 Pray 문구 없이 CTA/허용된 요약이 보인다. |
| BR-WID-02 | 오늘 기도 변형을 탭한다. | 오늘의 기도 진입 URL만 연다. | Pray가 없으면 노트/첫 Pray 작성으로 보낸다. | 작성이 필요한 이유와 다음 행동을 본다. |
| BR-WID-03 | 새 Pray 변형을 탭한다. | 앱의 기존 입력 화면을 연다. Widget Extension에서 직접 저장하지 않는다. | 항목이 없으면 항목 선택/생성 화면을 먼저 연다. | 앱에서 기존 저장 확인을 거쳐 새 Pray를 만든다. |
| BR-WID-04 | 선택 Pray 변형을 구성한다. | 유효한 Pray ID 하나만 설정한다. | 삭제/이동으로 무효가 되면 대상을 다시 고르거나 노트로 보낸다. | 대상이 사라졌음을 알리고 다시 선택할 수 있다. |
| BR-WID-05 | 카테고리 목록을 구성한다. | 한 카테고리의 Pray 요약을 해당 family에 읽을 수 있는 수로 표시한다. | 카테고리 삭제/빈 목록이면 빈 상태를 렌더링한다. | 추가할 수 있는 앱 진입 CTA가 보인다. |
| VR-WID-01 | 사용자가 제목 표시를 켠다. | 선택된 Pray 제목만 표시한다. 메모는 표시하지 않는다. | 제목 참조가 없으면 문구를 감춘 빈 상태로 대체한다. | 제목 노출 설정이 반영되고 메모는 비공개로 남는다. |
| SR-WID-01 | 앱이 위젯 스냅샷을 쓴다. | 필요한 ID·제목(동의 시)·상태만 App Group에 둔다. | 쓰기 실패 시 마지막 정상 스냅샷 또는 비공개 빈 상태를 사용한다. | 오류가 있어도 개인 JSON 전체가 위젯에 노출되지 않는다. |
| SR-WID-02 | 사용자 데이터 변경이 저장된다. | `PrayStore` 원자 저장 성공 이후에만 위젯 snapshot/timeline을 갱신한다. | 저장 실패면 새 상태를 성공처럼 공유하지 않는다. | 저장되지 않은 편집이 위젯에 완료된 것처럼 나타나지 않는다. |
| AR-WID-01 | Widget URL로 앱을 연다. | 앱 내부 허용 목적지와 현재 존재하는 ID만 허용한다. | 알 수 없는 URL/ID는 기본 노트로 보낸다. | 안전한 앱 화면이 열리며 오래된 목적지 오류가 안내된다. |
| BR-WID-06 | 위젯을 열거나 Pray 제목을 본다. | 기도/달성 기록을 만들지 않는다. | 없음. | 기록은 변하지 않고 앱 내 완료 조작에서만 추가된다. |
| ER-WID-01 | App Group 데이터가 없거나 손상됨. | 전체 노트를 위젯에서 임의로 읽지 않는다. | 빈 상태와 앱으로 이동할 링크를 제공한다. | 다시 앱을 열어 확인하라는 안내를 본다. |
| ER-WID-02 | 대상 Pray가 삭제/달성/이동되었거나 백업 복원됨. | 대상 ID를 사용할 때마다 현재 데이터와 대조한다. | 무효 ID는 선택 재설정 또는 노트로 fallback한다. | 앱은 오래된 Pray 화면 대신 유효한 목적지를 연다. |
| BR-WID-07 | 사용자가 노출 설정을 바꾼다. | 해당 위젯 구성에 반영하고 시스템 타임라인 갱신을 요청한다. | 시스템 갱신 지연 중에는 기존 안전한 표시를 유지한다. | 설정 변경 안내를 보고 갱신 후 선택한 모드를 본다. |

## 구현 영역

### 포함 범위 (In Scope)

- 홈 화면 small/medium/large family에 오늘 기도, 새 Pray, 선택 Pray, 카테고리 목록을 매핑한다.
- WidgetKit 렌더링, App Group의 최소 snapshot, 위젯별 configuration, 앱 내부 URL 라우팅을 구현한다.
- 문구 숨김 기본값, 선택적 제목, 오래된/무효 ID, 빈 저장소, 저장 후 timeline 갱신을 처리한다.

### 제외 범위 (Out of Scope)

- Lock Screen/StandBy family와 해당 표면의 텍스트 노출 보장.
- 위젯 내부에서 내용 편집/저장, 메모 표시, 원격 동기화/분석.
- 위젯을 열어 기도 완료/달성 기록을 자동 생성.

### 구현 단위와 관련 시스템/레이어

- `Praylist.xcodeproj/project.pbxproj`: 현재 타깃·파일 참조를 확인하고 필요한 경우 Widget Extension/App Group capability를 추가한다.
- **기존 위젯 branch에서 확인할 실제 파일:** Widget Extension의 `TimelineProvider`, timeline entry, widget view/configuration, App Group snapshot 저장, URL/intent 라우팅, entitlements. 재사용 여부와 실제 경로를 구현 착수 시 확정한다.
- **필요 시 신규 생성할 폴더:** 저장소 루트 `PraylistWidget/` 아래 timeline entry/provider, widget configuration/view, deep-link intent. 기존 브랜치의 명명/구조가 있으면 그 경로를 따른다.
- `Praylist/Services/PrayStore.swift`: 검증·원자 저장 성공 이후 snapshot 갱신을 트리거한다. `PrayData` 쓰기의 단일 소유자 원칙을 지킨다.
- `Praylist/Models/PrayData.swift`: ID·제목·달성 상태·카테고리 정보를 표시용 최소 snapshot으로 매핑한다. 영속 schema를 불필요하게 바꾸지 않는다.
- `Praylist/App/PraylistApp.swift` 및 실제 루트 화면 state 파일: Widget URL의 scheme/path/ID를 검증하고 네 가지 목적지를 연결한다.
- `Praylist/Resources/ko.lproj/`, `Praylist/Resources/en.lproj/`: 위젯, 설정, 빈 상태, 접근성 문구.
- `PraylistTests/`, `PraylistUITests/`, `scripts/generate-project.rb`: 프로젝트 타깃/테스트 및 생성 스크립트 반영 필요 여부를 확인한다.

## 완료 기준

### 기능·규칙·예외 완료

- 네 목적지가 실제 supported family 구성으로 홈 화면에 추가된다.
- 새 설치 기본값에서 Pray 문구가 숨겨지고, 제목 표시 선택 시에도 메모는 노출되지 않는다.
- 저장 성공 후 갱신되고, 유효 탭은 지정 화면으로, 무효/오래된 URL은 안전한 노트 화면으로 연결된다.
- 위젯 탭은 기도일/달성 상태를 바꾸지 않으며 새 Pray는 앱과 `PrayStore`를 통해서만 저장된다.
- 빈 데이터, 가득 찬 항목, 삭제/이동된 Pray, App Group 실패가 오류 종료나 개인정보 노출을 만들지 않는다.
- 한국어/영어, 라이트/다크, family 크기, VoiceOver, 시스템 틴트 지원을 확인한다.
- 서명 가능한 환경에서 App Group 접근과 실제 홈 화면 배치·갱신·탭을 확인하고 미검증 표면은 완료로 표시하지 않는다.

### 테스트용 완료 기준 (Given / When / Then)

- **Given** 새 설치로 노출 설정이 없는 상태, **When** 위젯을 추가하면, **Then** 제목/메모는 숨고 CTA 또는 안전 요약만 보인다.
- **Given** 유효한 Pray가 저장됨, **When** 오늘 기도 위젯을 탭하면, **Then** 오늘의 기도 화면이 열리고 `prayerDays`는 그대로다.
- **Given** 새 Pray 위젯, **When** 탭해 제목을 입력하고 저장하면, **Then** 선택 카테고리에 Pray가 정확히 하나 추가된다.
- **Given** 제목 표시를 명시적으로 허용함, **When** 선택 Pray 위젯을 렌더링하면, **Then** 제목만 보이고 메모는 없다.
- **Given** 선택 Pray가 삭제됨, **When** 해당 위젯을 탭하면, **Then** 오래된 화면 대신 안전한 노트/선택 화면이 열린다.
- **Given** 선택 카테고리가 비어 있음, **When** 목록 위젯을 렌더링하면, **Then** 빈 상태와 추가 화면 진입점이 보인다.
- **Given** 앱 JSON 저장이 실패함, **When** Pray를 수정하려 하면, **Then** 성공한 새 데이터처럼 App Group snapshot이 갱신되지 않는다.
- **Given** App Group snapshot이 누락/손상됨, **When** 위젯을 렌더링하고 탭하면, **Then** 안전한 빈 상태와 노트 화면이 제공된다.
- **Given** 허용되지 않은 widget URL/ID, **When** 앱이 이를 받으면, **Then** 해당 URL은 무시되고 노트 기본 화면이 열린다.
- **Given** 위젯이 배치된 상태, **When** 사용자가 제목 표시를 끄면, **Then** 시스템 갱신 이후 제목은 감춰지고 기도일은 생성되지 않는다.
