# 모바일 Slack 및 창 제어 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Skills의 모바일 UI를 Slack 모바일 구조로 바꾸고, iPhone·iPad·Mac의 창 제어와 Dock 표시 규칙을 기기별 요구사항에 맞게 통일한다.

**Architecture:** 기존 앱 콘텐츠는 유지하면서 `MobileAppSurface`가 iPhone 일반 앱에는 원형 뒤로가기 닫기 버튼, iPad 일반 앱에는 공통 `MacTrafficControls`를 주입한다. Finder는 iPhone·iPad 모두 전용 `뒤로가기 · 중앙 제목 · …` 도구막대와 `최근 항목 · 경력 · 개인` 하단 탐색을 사용한다. Skills는 compact 분기에서 상단 요약 카드와 전체 스킬 채널 목록을 하나의 세로 스크롤로 렌더링한다. 모바일 홈 셸에서는 앱 Dock을 제거하고, 배포 환경의 모바일 플랫폼은 화면 폭과 무관하게 iPhone/iPad 셸을 선택할 수 있도록 적응형 셸에 명시적인 기기 판별 지점을 둔다.

**Tech Stack:** Flutter, Material widgets, flutter_test, golden-free widget/semantics tests

---

### Task 1: 모바일 Skills를 Slack형 카드·채널 화면으로 변경

**Files:**
- Modify: `test/portfolio/skills_app_test.dart`
- Modify: `lib/portfolio/apps/skills_app.dart`

1. compact 화면에 상단 카드 영역과 하단 `#채널` 목록 전체가 존재하는 실패 테스트를 추가한다.
2. 기존 가로 카테고리 선택기와 단일 그룹 메시지 화면 대신 하나의 세로 스크롤로 구현한다.
3. 긴 텍스트·200% 글자 크기에서도 가로 넘침 없이 터치/마우스 스크롤되는지 검증한다.

### Task 2: 일반 앱의 iPhone과 iPad 창 닫기 UI를 분리

**Files:**
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/mobile/mobile_app_surface.dart`
- Create: `lib/portfolio/mobile/mobile_back_close_button.dart`

1. iPhone 일반 앱은 신호등 없이 원형 뒤로가기 버튼을 표시하고 닫히는 실패 테스트를 작성한다.
2. iPad 일반 앱은 기존 앱 헤더 위치에서 공통 신호등을 유지하는 테스트를 작성한다.
3. 공통 원형 닫기 버튼을 구현하고 헤더·Finder 도구막대에 기기별로 주입한다.

### Task 3: Finder 모바일·태블릿 공통 탐색 레이아웃 추가

**Files:**
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `test/portfolio/projects_finder_app_test.dart`
- Modify: `test/portfolio/projects_location_navigation_test.dart`
- Modify: `lib/portfolio/apps/projects_app.dart`
- Modify: `lib/portfolio/widgets/apple_finder_scaffold.dart`

1. iPhone·iPad Finder가 신호등과 사이드/원형 위치 목록 없이 뒤로가기, 중앙 제목, 비동작 `…`만 표시하는 실패 테스트를 작성한다.
2. 하단 Finder 탐색에 `최근 항목`, `경력`, `개인`만 표시되고 각 페이지가 전환되는 실패 테스트를 작성한다.
3. `최근 항목`은 전체 프로젝트 폴더 목록, `경력`과 `개인`은 기존 분류 목록에 연결한다.
4. 공통 Finder 스캐폴드에 모바일 도구막대와 하단 탐색 슬롯을 추가해 iPhone·iPad가 같은 컴포넌트를 사용하도록 구현한다.

### Task 4: macOS 신호등의 정적 글리프를 통일

**Files:**
- Modify: `test/portfolio/mac_desktop_test.dart`
- Modify: `test/portfolio/mobile_navigation_bar_test.dart`
- Modify: `lib/portfolio/macos/mac_traffic_controls.dart`

1. 빨간 원 안에는 X, 노란 원 안에는 마이너스, 초록 원은 빈 상태인 실패 테스트를 추가한다.
2. 눌림·호버에 따른 시각 상태를 만들지 않고 키보드·접근성 동작은 유지한다.
3. 데스크탑과 iPad가 동일 컴포넌트와 동일 간격을 쓰는지 검증한다.

### Task 5: 모바일·태블릿 홈 Dock을 제거하고 실제 모바일 기기를 판별

**Files:**
- Modify: `test/portfolio/apple_mobile_shell_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `lib/portfolio/mobile/apple_mobile_shell.dart`
- Modify: `lib/portfolio/mobile/apple_home_grid.dart`
- Modify: `lib/portfolio/widgets/adaptive_portfolio_shell.dart`

1. iPhone·iPad 홈에서 앱 Dock이 없고 모든 앱 아이콘이 스크롤로 접근 가능한 실패 테스트를 작성한다.
2. 모바일 플랫폼으로 판별된 넓은 화면도 Mac 셸 대신 iPad 셸을 선택하는 테스트를 작성한다.
3. Dock 렌더링과 예약 여백을 제거하고 적응형 기기 판별을 구현한다.

### Task 6: 모바일·태블릿 화면 모드 선택 UI 재구성

**Files:**
- Modify: `test/portfolio/settings_app_test.dart`
- Modify: `test/portfolio/settings_profile_svg_test.dart`
- Modify: `lib/portfolio/apps/settings_app.dart`

1. 데스크탑 설정의 사이드바·화면 모드 구성이 그대로 유지되는 테스트를 고정한다.
2. iPhone·iPad는 사이드바 없이 화면 폭에 비례한 라이트/다크 미리보기를 나란히 표시하는 실패 테스트를 작성한다.
3. 두 선택지는 즉시 전체 테마를 전환하고, 200% 글자 크기에서는 가로 넘침 없이 스크롤되도록 구현한다.

### Task 7: 라이트·다크 회귀·시각 검증 및 요구사항 문서 갱신

**Files:**
- Modify: `docs/plans/2026-09-03-portfolio-requirements-checklist.md`

1. 관련 테스트를 먼저 실행하고 전체 테스트와 `flutter analyze`를 실행한다.
2. iPhone, iPad, Mac 크기와 라이트·다크 양쪽으로 로컬 화면을 확인하고 Skills·Finder·설정·창 헤더·홈 화면을 캡처해 비교한다.
3. 기존 전체 앱도 라이트·다크에서 렌더링 및 스크롤 오류가 없는지 점검하고 체크리스트를 실제 검증 결과로 갱신한다.
4. 변경을 한국어 Conventional Commits 형식으로 기능 단위마다 나누어 커밋한다.
