# Terminal Typography and Line Reveal Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 터미널 내부 글자를 단일 스타일로 통일하고 여러 줄을 500ms 등장 모션과 300ms 휴지 간격으로 순차 노출한다.

**Architecture:** `TerminalApp`의 기존 transcript 데이터 흐름은 유지한다. 공용 텍스트 스타일을 모든 출력과 입력에 적용하고, 각 transcript 행에 묶음 내 순번을 저장해 reveal 위젯이 자신의 시작 시점을 계산한다. 마지막 활성 행의 실제 완료 콜백이 상태 게이트를 열기 전까지 입력 영역은 마운트하지 않는다.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: 타이포그래피와 모션 계약 테스트

**Files:**
- Modify: `test/portfolio/terminal_app_theme_test.dart`

1. 터미널의 프롬프트, 입력값, 명령 echo, 도움말 명령·설명, 일반 출력의 `fontFamily`, fallback, size, weight, height가 같은지 검사하는 테스트를 작성한다.
2. 첫 두 transcript 행의 opacity와 세로 이동이 첫 500ms 동안 진행되고, 300ms 동안 다음 행이 멈춘 뒤 800ms 시점부터 진행하는 테스트를 작성한다.
3. `flutter test test/portfolio/terminal_app_theme_test.dart`를 실행해 스타일 및 reveal 위젯이 없어 실패하는 것을 확인한다.

### Task 2: 공용 스타일과 순차 reveal 구현

**Files:**
- Modify: `lib/portfolio/apps/terminal_app.dart`

1. `_terminalTextStyle`에 동일한 굵기를 명시하고 도움말, 프롬프트, 입력이 모두 이 helper를 사용하게 한다.
2. `_TerminalLine`에 출력 묶음 내 reveal 순번을 저장한다.
3. 각 transcript 행을 500ms fade/상승시키고 다음 순번은 800ms 뒤 시작하는 reveal 위젯으로 감싼다.
4. 새 명령 제출 시 새 활성 묶음을 만들고 기존 출력은 완료 상태로 유지한다.
5. `flutter test test/portfolio/terminal_app_theme_test.dart`를 실행해 통과를 확인한다.

### Task 3: 출력 완료 뒤 입력 표시

**Files:**
- Modify: `lib/portfolio/apps/terminal_app.dart`
- Modify: `test/portfolio/terminal_app_theme_test.dart`
- Modify: `test/portfolio/app_content_test.dart`
- Modify: `test/portfolio/portfolio_scroll_behavior_test.dart`

1. 초기 출력과 명령 결과의 마지막 활성 행이 끝나기 전까지 입력 위젯과 레이아웃 높이가 없는 테스트를 작성한다.
2. 마지막 행의 `onEnd`가 현재 묶음 토큰을 확인한 뒤 입력 상태 게이트를 열도록 구현한다.
3. 입력을 마운트한 다음 프레임에 포커스와 끝 스크롤을 복원한다.
4. 모션 축소 설정에서는 즉시 완료하고, 설정을 다시 바꿔도 입력과 출력이 재차 숨겨지지 않는지 검증한다.
5. 출력 진행 중 터치 또는 마우스 클릭 한 번이 활성 행 전체를 완료하고 입력을 표시하는 테스트를 먼저 실패시킨다.
6. 터미널 surface의 pointer-down에서 진행 중이면 기존 묶음 완료 경로를 호출하고, 완료 상태이면 기존 입력 포커스를 유지한다.
7. 반복 명령·접근성·스크롤 테스트의 가상 시간을 새 계약에 맞춘다.
8. `dart format`, 터미널 관련 테스트, `flutter analyze`, 전체 `flutter test`, `dart run tool/build_web.dart`를 차례로 실행한다.
9. `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765`로 로컬 확인 서버를 유지한다.
