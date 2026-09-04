# 포트폴리오 터미널 명령 인터페이스 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** 포트폴리오 데이터를 실제 터미널 명령처럼 탐색하고, 최소한의 점멸 커서 입력으로 조작하는 Flutter 터미널을 구현한다.

**Architecture:** 순수 동기 `TerminalEngine`이 명령을 해석하고 immutable 최근 커밋 스냅샷과 `PortfolioData`로 문자열 결과를 만든다. `TerminalApp`은 초기 `help` transcript, 입력 포커스, transcript 초기화와 스크롤만 소유한다.

**Tech Stack:** Flutter, Dart, flutter_test

---

### Task 1: 명령 엔진 계약

**Files:**
- Create: `lib/portfolio/terminal/terminal_git_history.dart`
- Modify: `lib/portfolio/terminal/terminal_engine.dart`
- Test: `test/portfolio/terminal_engine_test.dart`

1. `help`의 명령·설명 행과 `npm run dev` 제거를 기대하는 실패 테스트를 작성한다.
2. `ls`가 personal 프로젝트만, `git log`가 주입한 커밋을 최신순으로 출력하는 실패 테스트를 작성한다.
3. `flutter test test/portfolio/terminal_engine_test.dart`로 예상 실패를 확인한다.
4. immutable `TerminalGitCommit`과 기본 최근 커밋 스냅샷을 추가한다.
5. 엔진을 최소 수정해 테스트를 통과시킨다.
6. 엔진 테스트를 다시 실행하고 커밋한다.

### Task 2: 프롬프트와 입력 경험

**Files:**
- Modify: `lib/portfolio/data/portfolio_data.dart`
- Modify: `lib/portfolio/apps/terminal_app.dart`
- Test: `test/portfolio/app_content_test.dart`
- Test: `test/portfolio/terminal_app_theme_test.dart`

1. `포트폴리오: ~$` 프롬프트, 초기 help 출력, placeholder·전송 버튼 부재, autofocus와 clear 초기화를 기대하는 실패 테스트를 작성한다.
2. 관련 위젯 테스트의 예상 실패를 확인한다.
3. transcript를 `initState`에서 help 결과로 초기화한다.
4. 입력부를 프롬프트·TextField 한 행으로 단순화하고 hint·버튼·hover·selection 강조를 제거한다.
5. Enter 제출과 `clear` 후 빈 transcript를 검증하고 커밋한다.

### Task 3: 회귀 검증과 요구사항 기록

**Files:**
- Modify: `docs/plans/2026-09-03-portfolio-requirements-checklist.md`

1. 포맷, 정적 분석, 전체 테스트와 웹 릴리스 빌드를 실행한다.
2. iPhone/iPad/desktop의 Light/Dark 터미널을 시각 점검한다.
3. 요구사항 체크리스트와 최근 커밋 스냅샷을 갱신한다.
4. 한국어 Conventional/Angular 형식으로 커밋을 나눈다.
5. `dev`를 먼저 push하고 `main`을 fast-forward한 뒤 다시 `dev`로 돌아온다.
