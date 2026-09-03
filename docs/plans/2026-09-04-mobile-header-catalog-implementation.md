# Mobile Header and Catalog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 모바일 공용 헤더의 정렬·터치 범위를 바로잡고, 회사 디렉토리 명칭과 폼팩터별 앱 카탈로그·사진 placeholder를 추가한다.

**Architecture:** `AppleMobileNavigationHeader`가 iPhone/iPad 헤더 chrome을 한 번만 구현하고 앱별 leading만 주입받는다. desktop과 mobile launcher catalog는 분리하며 `photos`는 공용 앱 route와 artwork 체계에 포함한다. Projects 내부 ID는 유지하고 공개 label만 교체한다.

**Tech Stack:** Flutter, Dart, Widget tests, Flutter Web

---

### Task 1: 공용 모바일 헤더와 클릭 영역

**Files:**
- Create: `lib/portfolio/widgets/apple_mobile_navigation_header.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`
- Modify: `lib/portfolio/mobile/mobile_back_close_button.dart`
- Modify: `lib/portfolio/widgets/apple_finder_scaffold.dart`
- Test: `test/portfolio/mobile_navigation_bar_test.dart`

**Step 1: Write the failing test**

- iPhone 일반 앱 제목의 높이가 30px 미만이고 원형 leading과 세로 중심이 1px 이내인지 검사한다.
- iPhone 일반 앱과 iPhone/iPad Projects에 `…` key가 존재하는지 검사한다.
- 제목, 제목 양쪽 빈 공간, `…`를 탭해도 화면이 유지되고 leading 44×44만 닫는지 검사한다.
- Projects root semantics label이 정확히 `Close Projects window`, 크기가 44×44인지 검사한다.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/mobile_navigation_bar_test.dart --reporter expanded`

Expected: FAIL because the regular title is 44px high, regular apps omit `…`, and Projects close semantics covers the full header.

**Step 3: Write minimal implementation**

- 공용 헤더가 surface/border, leading, centered natural-height title, inert trailing `…`를 렌더링한다.
- 일반 앱과 mobile Finder가 같은 헤더를 사용하게 하고 mobile Finder는 전체 폭 drag gesture를 우회한다.
- `MobileBackCloseButton` semantics를 독립 container로 만든다.

**Step 4: Run tests and verify green**

Run: `flutter test test/portfolio/mobile_navigation_bar_test.dart test/portfolio/mac_finder_window_chrome_test.dart --reporter compact`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/widgets/apple_mobile_navigation_header.dart lib/portfolio/mobile/mobile_app_surface.dart lib/portfolio/mobile/mobile_back_close_button.dart lib/portfolio/widgets/apple_finder_scaffold.dart test/portfolio/mobile_navigation_bar_test.dart
git commit -m "fix(mobile): 공용 헤더 정렬과 터치 영역 수정"
```

### Task 2: 경력 디렉토리를 회사로 변경

**Files:**
- Modify: `lib/portfolio/apps/projects_app.dart`
- Modify: `test/portfolio/projects_location_navigation_test.dart`
- Modify: `test/portfolio/projects_finder_app_test.dart`
- Modify: `test/portfolio/projects_responsive_alignment_test.dart`
- Modify: `test/portfolio/mac_finder_window_chrome_test.dart`

**Step 1: Write the failing test**

- desktop sidebar와 iPhone/iPad 하단 탐색에 `회사`가 표시되고 `경력`이 없음을 검사한다.
- semantics가 desktop `회사 위치 열기`, mobile `Open 회사`인지 검사한다.

**Step 2: Run test to verify it fails**

Run: `flutter test test/portfolio/projects_location_navigation_test.dart --reporter expanded`

Expected: FAIL with the existing `경력` label.

**Step 3: Write minimal implementation**

`_ProjectsLocation.career`의 public label만 `회사`로 바꾸고 내부 enum/id/category/key는 유지한다.

**Step 4: Run tests and verify green**

Run: `flutter test test/portfolio/projects_location_navigation_test.dart test/portfolio/projects_finder_app_test.dart test/portfolio/projects_responsive_alignment_test.dart test/portfolio/mac_finder_window_chrome_test.dart --reporter compact`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/apps/projects_app.dart test/portfolio/projects_location_navigation_test.dart test/portfolio/projects_finder_app_test.dart test/portfolio/projects_responsive_alignment_test.dart test/portfolio/mac_finder_window_chrome_test.dart
git commit -m "fix(finder): 경력 디렉토리를 회사로 변경"
```

### Task 3: 폼팩터별 앱 순서와 사진 placeholder

**Files:**
- Create: `lib/portfolio/apps/photos_app.dart`
- Modify: `lib/portfolio/models/portfolio_app_id.dart`
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Modify: `lib/portfolio/widgets/apple_app_icon.dart`
- Modify: `lib/portfolio/widgets/apple_app_artwork.dart`
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Test: `test/portfolio/launcher_catalog_test.dart`
- Test: `test/portfolio/apple_mobile_shell_test.dart`
- Test: `test/portfolio/apple_app_artwork_test.dart`
- Test: `test/portfolio/app_content_test.dart`

**Step 1: Write the failing tests**

- desktop catalog 순서를 `About, Skills, Projects, Terminal, GitHub, Mail, 설정, Trash`로 검사한다.
- mobile catalog에 About이 없고 Photos가 Terminal 바로 뒤에 있으며 나머지 순서를 검사한다.
- 모바일 메모로 About이 계속 열리고 사진 아이콘은 `photos-app` 준비 중 화면을 여는지 검사한다.
- Photos가 공용 artwork frame과 Light/Dark surface를 사용하는지 검사한다.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/launcher_catalog_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart --reporter expanded`

Expected: FAIL because catalogs are shared and Photos does not exist.

**Step 3: Write minimal implementation**

- `PortfolioAppId.photos`, desktop/mobile catalogs, `사진` label과 code-native artwork를 추가한다.
- `AppleHomeGrid`는 mobile catalog만 사용한다.
- `PhotosApp`은 스크롤 가능한 `사진 준비 중` empty surface를 제공하고 content router에 연결한다.

**Step 4: Run tests and verify green**

Run: `flutter test test/portfolio/launcher_catalog_test.dart test/portfolio/apple_mobile_shell_test.dart test/portfolio/apple_app_artwork_test.dart test/portfolio/app_content_test.dart test/portfolio/portfolio_scroll_behavior_test.dart --reporter compact`

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/portfolio/apps/photos_app.dart lib/portfolio/models/portfolio_app_id.dart lib/portfolio/mobile/apple_home_grid.dart lib/portfolio/widgets/apple_app_icon.dart lib/portfolio/widgets/apple_app_artwork.dart lib/portfolio/apps/portfolio_app_content.dart test/portfolio
git commit -m "feat(mobile): 사진 자리와 기기별 앱 순서 추가"
```

### Task 4: 요구사항 문서와 전체 검증

**Files:**
- Modify: `docs/plans/2026-09-03-portfolio-requirements-checklist.md`

**Step 1: Update the checklist**

공용 헤더, 44×44 닫기 영역, `…`, 회사 label, form factor별 launcher 순서, About 중복 제거, Photos placeholder의 상태와 근거를 기록한다.

**Step 2: Run all verification**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter test --reporter compact
flutter analyze
flutter build web --release --base-href /portfolio_hesu/ --pwa-strategy=none
flutter build web --release --base-href / --pwa-strategy=none
git diff --check
```

Expected: all commands succeed.

**Step 3: Visual QA**

390×844, 834×1112, 1280×720에서 헤더·카탈로그·회사 label·Photos placeholder를 확인하고 Light/Dark 전환을 점검한다.

**Step 4: Commit**

```bash
git add docs/plans/2026-09-03-portfolio-requirements-checklist.md
git commit -m "docs(requirements): 모바일 헤더와 앱 순서 검증 추가"
```
