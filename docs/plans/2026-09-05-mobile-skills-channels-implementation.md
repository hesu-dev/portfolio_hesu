# Mobile Skills Channels Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** 모바일 Skills에 자격증 카드 1개, 데스크탑과 동일한 3개 채널, 고정 헤더와 메시지 피드를 갖춘 채널 상세 뎁스를 구현한다.

**Architecture:** `PortfolioData`가 자격증과 스킬 활동 본문을 소유하고 `SkillsApp`의 compact 분기만 nullable 선택 상태로 목록/상세을 교체한다. 태블릿과 데스크탑은 3-pane, 모바일은 2뎁스 탐색을 유지하되, 세 폼팩터의 채널 내부는 공통 헤더·활동 피드·메시지 컴포넌트를 사용한다. 모바일 상세 헤더만 스크롤 목록 바깥에 둔다.

**Tech Stack:** Flutter, Dart, Material widgets, `flutter_test`

---

### Task 1: 자격증과 스킬 활동 데이터 계약

**Files:**
- Modify: `lib/portfolio/data/portfolio_data.dart`
- Test: `test/portfolio/portfolio_data_test.dart`

1. 자격증과 스킬 활동 컬렉션의 방어 복사·불변성 및 검색 텍스트 포함 실패 테스트를 작성한다.
2. `flutter test test/portfolio/portfolio_data_test.dart`를 실행해 새 계약 때문에 실패하는지 확인한다.
3. 선택형 `certifications`와 `activityDescriptions` 필드 및 실제 포트폴리오 콘텐츠를 최소 구현한다.
4. 같은 테스트를 다시 실행해 통과를 확인한다.

### Task 2: 모바일 1뎁스와 폼팩터 분기

**Files:**
- Modify: `lib/portfolio/apps/skills_app.dart`
- Test: `test/portfolio/skills_app_test.dart`

1. 자격증 카드가 정확히 1개이고 그룹 기반 채널이 정확히 3개이며 개별 스킬 채널이 없는 실패 테스트를 작성한다.
2. compact iPhone만 모바일 구조를 사용하고 `tablet: true`는 좁은 폭에서도 wide 구조를 유지하는 실패 테스트를 작성한다.
3. focused 테스트를 실행해 예상 실패를 확인한다.
4. 모바일 카드와 그룹 채널 버튼을 최소 구현하고 폼팩터 분기를 수정한다.
5. focused 테스트를 다시 실행해 통과를 확인한다.

### Task 3: 모바일 채널 상세 뎁스

**Files:**
- Modify: `lib/portfolio/apps/skills_app.dart`
- Test: `test/portfolio/skills_app_test.dart`

1. 채널 탭, 고정 `# 채널명 / 1명의 멤버 / 1개의 탭` 헤더, 오늘 날짜, 프로필 아바타, 이름, 시간, 활동 본문과 내부 뒤로가기를 검증하는 실패 테스트를 작성한다.
2. 테스트를 실행해 상세 뎁스가 없어 실패하는지 확인한다.
3. nullable 모바일 선택 상태, 고정 헤더, 스크롤 메시지 목록과 뒤로가기를 최소 구현한다.
4. 스크롤 전후 헤더 위치가 유지되고 메시지만 이동하는지 포함해 테스트 통과를 확인한다.

### Task 4: 통합 계약 갱신

**Files:**
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/portfolio/portfolio_scroll_behavior_test.dart`
- Modify: `docs/plans/2026-09-03-portfolio-requirements-checklist.md`

1. 이전의 그룹별 요약 카드와 10개 평면 채널 기대값을 새 자격증 카드·3채널·2뎁스 계약으로 바꾼다.
2. 관련 통합 테스트를 실행해 모든 폼팩터와 전역 스크롤 동작을 확인한다.
3. 요구사항 체크리스트의 Skills 항목을 최신 동작으로 갱신한다.

### Task 5: 채널 내부 콘텐츠 공통화

**Files:**
- Modify: `lib/portfolio/apps/skills_app.dart`
- Test: `test/portfolio/skills_app_test.dart`

1. 데스크탑·태블릿에서 모바일과 같은 채널 헤더, 오늘 날짜, 프로필 아바타, 이름, 시간, 활동 본문이 노출되는 실패 테스트를 작성한다.
2. wide 전용 고정 영문 본문과 모바일 전용 메시지 렌더러를 제거한다.
3. `_SkillChannelHeader`, `_SkillActivityFeed`, `_SkillActivityMessage`를 공통화하고 모바일에는 뒤로가기만 주입한다.
4. Development와 다른 채널 전환을 데스크탑·태블릿·모바일에서 검증한다.

### Task 6: 최종 검증

**Files:**
- Verify: all modified Dart files

1. `dart format`으로 수정 파일을 포맷한다.
2. `flutter test test/portfolio/skills_app_test.dart test/portfolio/app_content_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/portfolio_scroll_behavior_test.dart test/portfolio/portfolio_data_test.dart`를 실행한다.
3. `flutter analyze`를 실행한다.
4. `flutter test` 전체를 실행한다.
5. iPhone 크기로 실제 렌더링을 확인하고 목록·상세 화면에 overflow가 없는지 검수한다.
