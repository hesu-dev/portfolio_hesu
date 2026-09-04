# 모바일 Instagram형 프로필 앱 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** iPhone과 iPad 홈의 첫 아이콘으로 독립적인 Instagram형 프로필 앱을 제공하고 기존 Notes/About 구현은 보존한다.

**Architecture:** `PortfolioAppId.profile`을 모바일 카탈로그에만 추가하고 공용 아이콘·라우터·모바일 창 표면에 연결한다. 새 `ProfileApp`은 `PortfolioData`에서 모든 콘텐츠를 읽는 단일 반응형 스크롤 화면이며, 기존 About과 데스크톱 카탈로그에는 영향을 주지 않는다.

**Tech Stack:** Flutter, Dart, Material widgets, CustomPainter, flutter_test

---

### Task 1: 모바일 프로필 계약을 실패 테스트로 고정

**Files:**
- Create: `test/portfolio/profile_app_test.dart`
- Modify: `test/portfolio/launcher_catalog_test.dart`
- Modify: `test/portfolio/mobile_notes_about_test.dart`
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/portfolio/portfolio_data_test.dart`

**Step 1: Write the failing test**

문자열 기반 기대값과 홈 키를 사용해 모바일 카탈로그 첫 항목 `profile`, Notes 위젯 미노출, 첫 아이콘 위치, 새 프로필 화면의 데이터·라이트/다크·스크롤 계약을 작성한다. 기존 About 연속 메모 테스트는 보존한다.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/profile_app_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/mobile_notes_about_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/portfolio_data_test.dart`

Expected: 새 `profile` 항목과 `profile-app` 화면이 없어 의도한 assertion이 실패한다.

**Step 3: Commit**

```bash
git add test/portfolio/profile_app_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/mobile_notes_about_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/portfolio_data_test.dart
git commit -m "test(profile): 모바일 프로필 앱 명세"
```

### Task 2: 프로필 식별자와 공용 아이콘 연결

**Files:**
- Modify: `lib/portfolio/models/portfolio_app_id.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `test/portfolio/apple_app_artwork_test.dart`
- Modify: `test/portfolio/app_content_test.dart`

**Step 1: Write the failing test**

프로필 라벨이 `프로필`이고, 복제 비트맵이나 범용 Material 아이콘 없이 코드 네이티브 프로필 artwork를 렌더하는 테스트를 추가한다.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart`

Expected: 프로필 artwork와 라벨이 없어 실패한다.

**Step 3: Write minimal implementation**

`PortfolioAppId.profile`을 추가하고 모바일 카탈로그 맨 앞에만 배치한다. 공용 라벨과 그라데이션 원형 프로필 마크 painter를 추가하고 모든 exhaustive switch를 갱신한다.

**Step 4: Run test to verify it passes**

Run: `flutter test test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/portfolio_data_test.dart`

Expected: PASS

**Step 5: Commit**

```bash
git add lib/portfolio/models/portfolio_app_id.dart lib/portfolio/widgets/apple_app_icon.dart lib/portfolio/widgets/apple_app_artwork.dart test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart
git commit -m "feat(profile): 모바일 프로필 아이콘 추가"
```

### Task 3: Instagram형 프로필 콘텐츠 구현

**Files:**
- Create: `lib/portfolio/apps/profile_app.dart`
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Modify: `test/portfolio/profile_app_test.dart`
- Modify: `test/portfolio/portfolio_scroll_behavior_test.dart`

**Step 1: Write the failing test**

주입한 identity, 프로젝트·스킬·경력 통계, GitHub/이메일 액션, 하이라이트, 전체 프로젝트 3열 타일, 라이트/다크 및 200% 글자 크기 계약을 먼저 작성한다.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/profile_app_test.dart test/portfolio/portfolio_scroll_behavior_test.dart`

Expected: `ProfileApp`과 `profile-scroll`이 없어 실패한다.

**Step 3: Write minimal implementation**

공용 모바일 헤더와 중복되지 않는 `ProfileApp`을 `CustomScrollView`로 구현한다. 모든 콘텐츠는 `PortfolioData`에서 가져오며 외부 액션은 기존 `ExternalLauncher`를 사용한다.

**Step 4: Run test to verify it passes**

Run: `flutter test test/portfolio/profile_app_test.dart test/portfolio/portfolio_scroll_behavior_test.dart test/portfolio/app_content_test.dart`

Expected: PASS

**Step 5: Commit**

```bash
git add lib/portfolio/apps/profile_app.dart lib/portfolio/apps/portfolio_app_content.dart test/portfolio/profile_app_test.dart test/portfolio/portfolio_scroll_behavior_test.dart
git commit -m "feat(profile): 인스타그램형 프로필 화면 구현"
```

### Task 4: 모바일 홈에서 Notes 위젯 제거 및 첫 아이콘 배치

**Files:**
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Modify: `test/portfolio/mobile_notes_about_test.dart`
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/portfolio/launcher_catalog_test.dart`

**Step 1: Run the existing failing tests**

Run: `flutter test test/portfolio/mobile_notes_about_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/launcher_catalog_test.dart`

Expected: 기존 Notes 위젯과 새 첫 프로필 아이콘이 충돌해 실패한다.

**Step 2: Write minimal implementation**

`AppleHomeGrid`의 Notes 버튼과 import만 제거하고 그리드 상단 패딩을 기기별로 조정한다. 프로필은 모바일 카탈로그 첫 항목이므로 iPhone/iPad 모두 최상단 첫 셀에 놓인다.

**Step 3: Run test to verify it passes**

Run: `flutter test test/portfolio/mobile_notes_about_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/launcher_catalog_test.dart`

Expected: PASS

**Step 4: Commit**

```bash
git add lib/portfolio/mobile/apple_home_grid.dart test/portfolio/mobile_notes_about_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/launcher_catalog_test.dart
git commit -m "refactor(mobile): 메모 위젯을 프로필 앱으로 교체"
```

### Task 5: 전체 검증과 요구사항 기록

**Files:**
- Modify: `docs/plans/2026-09-03-portfolio-requirements-checklist.md`

**Step 1: Format and analyze**

Run: `dart format lib test`

Run: `flutter analyze`

Expected: No issues found.

**Step 2: Run targeted and full tests**

Run: `flutter test test/portfolio/profile_app_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/launcher_catalog_test.dart test/portfolio/apple_app_artwork_test.dart test/portfolio/portfolio_scroll_behavior_test.dart`

Run: `flutter test`

Expected: All tests passed.

**Step 3: Verify the running app**

Hot reload the existing `http://127.0.0.1:7357/` Flutter session and inspect iPhone/iPad widths in both themes. Confirm the first icon, shared header, scrolling, project grid, and absence of the Notes widget.

**Step 4: Update requirements and commit**

```bash
git add docs/plans/2026-09-03-portfolio-requirements-checklist.md
git commit -m "docs(requirements): 모바일 프로필 앱 검증 반영"
```

**Step 5: Integrate branches**

Push `dev`, fast-forward `main` from `dev`, push `main`, then switch back to `dev`. Verify local/remote branches and worktrees contain only the requested `main` and `dev` state.
