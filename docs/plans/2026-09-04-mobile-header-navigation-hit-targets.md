# Mobile Header, Finder Navigation, and Hit Targets Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** 모바일 제목을 화면 중앙에 고정하고, Projects Finder의 내부 뒤로가기와 창 닫기를 구분하며, macOS 신호등의 촘촘한 시각 간격을 유지한 채 접근 가능한 포인터 영역을 확보한다.

**Architecture:** 일반 iPhone 앱 바는 좌우 대칭 슬롯을 둔 `Stack`으로 제목을 전체 바 중심에 배치한다. Projects Finder는 공용 창 chrome이 모바일 상태에 맞춰 선행 제어를 빌드하도록 하여 Finder의 `canGoBack/onBack`을 우선하고 루트에서만 `onClose`를 호출한다. 신호등은 포인터 영역의 폭·높이와 원의 시각 중심 간격을 분리한다.

**Tech Stack:** Flutter, Material widgets, flutter_test

---

### Task 1: iPhone 일반 앱 제목 중앙 정렬

**Files:**
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`

1. iPhone 제목의 중심이 화면 중심과 일치하고 `TextAlign.center`를 사용하는 실패 테스트를 작성한다.
2. `flutter test test/portfolio/mobile_navigation_bar_test.dart --plain-name 'every non-Projects iPhone app uses one circular back close button'`로 기존 왼쪽 정렬 때문에 실패하는지 확인한다.
3. iPhone 헤더를 좌우 대칭 영역을 가진 `Stack`으로 바꾸되 iPad의 기존 배치는 유지한다.
4. 같은 테스트를 다시 실행해 통과를 확인한다.
5. `fix(mobile): 아이폰 앱 제목을 화면 중앙에 정렬`로 커밋한다.

### Task 2: Projects Finder 내부 뒤로가기 우선

**Files:**
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/mobile/mobile_back_close_button.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`
- Modify: `lib/portfolio/widgets/apple_finder_scaffold.dart`

1. iPhone과 iPad에서 상세 진입 후 원형 버튼이 `Back` 의미를 가지며 목록으로 돌아가고, 루트에서는 `Close` 의미로 바뀌어 홈으로 닫히는 실패 테스트를 작성한다.
2. 해당 테스트만 실행해 현재 상세에서도 창이 닫혀 실패하는지 확인한다.
3. `MobileBackCloseButton`에 Back/Close 동작 의미를 추가하고, Finder chrome이 모바일 `canGoBack/onBack` 상태로 선행 버튼을 다시 빌드하게 한다.
4. 해당 테스트와 모바일 내비게이션 전체 테스트를 실행한다.
5. `fix(finder): 모바일 상세에서 내부 뒤로가기를 우선`으로 커밋한다.

### Task 3: macOS 신호등 포인터 영역 확대

**Files:**
- Modify: `test/portfolio/mac_desktop_test.dart`
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/macos/mac_traffic_controls.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`

1. 데스크톱 히트 영역이 최소 28×32이고 시각 중심은 24px 간격이며, iPad 히트 영역 높이는 44px인 실패 테스트를 작성한다.
2. 두 테스트를 실행해 현재 24×32 때문에 실패하는지 확인한다.
3. 신호등 타깃 폭을 28px로 분리하고 시각 원을 가운데로 모아 24px 중심 간격을 유지한다. iPad 호출부에는 44px 높이를 사용한다.
4. 관련 신호등 및 모바일 테스트를 실행한다.
5. `fix(accessibility): 신호등 포인터 영역을 확대`로 커밋한다.

### Task 4: Control Center 수동 테마 문구

**Files:**
- Modify: `test/portfolio/mac_chrome_theme_test.dart`
- Modify: `lib/portfolio/macos/mac_menu_bar.dart`

1. Display 타일이 수동 Light/Dark 선택을 안내하고 시스템 추종 문구를 노출하지 않는 실패 테스트를 작성한다.
2. 해당 테스트를 실행해 오래된 문구로 실패하는지 확인한다.
3. 부제목을 수동 선택 모델에 맞게 바꾼다.
4. 관련 테스트를 실행한다.
5. `fix(theme): 제어 센터의 수동 테마 안내를 수정`으로 커밋한다.

### Task 5: 최종 검증

1. 변경한 테스트 파일 전체를 실행한다.
2. `flutter analyze`로 변경 파일의 정적 분석 결과를 확인한다.
3. `dart format --output=none --set-exit-if-changed`로 포맷을 확인한다.
4. `git diff --check`와 `git status --short`로 커밋 경계를 검증한다.
