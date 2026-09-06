# Skill Brand Avatars Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** Skills 앱의 세 채널에 있는 모든 현재 기술 프로필 아바타를 데스크톱, 태블릿, 모바일에서 해당 브랜드 로고로 표시한다.

**Architecture:** `skills_app.dart`에 기술 이름과 로컬 SVG 경로의 단일 매핑을 두고, 공통 메시지 아바타 렌더러가 매핑된 기술에는 로고를, 알 수 없는 기술에는 기존 첫 글자를 표시한다. 세 폼 팩터가 공유하는 `_SkillActivityMessage`만 변경해 모든 채널에 동일하게 적용한다.

**Tech Stack:** Flutter, Dart, flutter_svg, flutter_test, Devicon SVG assets

---

### Task 1: 로고·에셋 실패 계약

**Files:**
- Modify: `test/portfolio/skills_app_test.dart`

**Step 1: Write the failing tests**

데스크톱, 태블릿, 모바일 각각에서 실제 `portfolioData`의 세 채널을 순회해 현재 열 개 기술마다 `skills-message-logo-<skill>` 키를 가진 `SvgPicture`가 정확한 asset 경로를 사용하는지 검사한다. 별도 asset bundle 테스트에서 열 개 SVG 문자열이 모두 `<svg`를 포함하는지 확인하고, 미등록 기술은 기존 첫 글자 아바타를 유지하는지도 검사한다.

**Step 2: Run tests to verify RED**

```bash
flutter test test/portfolio/skills_app_test.dart --plain-name 'uses every skill brand logo across desktop tablet and mobile channels'
```

Expected: FAIL because no `skills-message-logo-*` widgets exist.

### Task 2: 로컬 SVG와 공통 아바타 구현

**Files:**
- Create: `assets/icons/skills/flutter.svg`
- Create: `assets/icons/skills/dart.svg`
- Create: `assets/icons/skills/react.svg`
- Create: `assets/icons/skills/java.svg`
- Create: `assets/icons/skills/notion.svg`
- Create: `assets/icons/skills/slack.svg`
- Create: `assets/icons/skills/trello.svg`
- Create: `assets/icons/skills/figma.svg`
- Create: `assets/icons/skills/adobe-photoshop.svg`
- Create: `assets/icons/skills/adobe-illustrator.svg`
- Modify: `pubspec.yaml`
- Modify: `lib/portfolio/apps/skills_app.dart`

**Step 1: Add the registered local assets**

Devicon의 `original.svg` 컬러 로고 열 개를 `assets/icons/skills/`에 추가하고 해당 디렉터리를 Flutter assets에 등록한다.

**Step 2: Implement the minimal renderer**

기술 이름을 정확한 asset 경로로 매핑한다. `_SkillActivityAvatar`는 알려진 기술이면 흰색 계열 원과 테두리 안에 `SvgPicture.asset`을 표시하고, 알 수 없는 기술이면 기존 인덱스 색상과 첫 글자를 유지한다. 기존 외부 semantics와 키는 바꾸지 않는다.

**Step 3: Run tests to verify GREEN**

```bash
flutter test test/portfolio/skills_app_test.dart
```

Expected: all Skills tests pass.

### Task 3: 회귀·실행 검증과 커밋

**Files:**
- Modify if needed: `lib/portfolio/apps/skills_app.dart`
- Modify if needed: `test/portfolio/skills_app_test.dart`

**Step 1: Format and inspect**

```bash
dart format lib/portfolio/apps/skills_app.dart test/portfolio/skills_app_test.dart
git diff --check
```

**Step 2: Run full verification**

```bash
flutter test
flutter analyze
dart run tool/build_web.dart
```

Expected: all commands exit 0.

**Step 3: Hot reload the running app**

실행 중인 `flutter run -d chrome` 세션에 `r`을 보내고 핫 리로드 성공 출력을 확인한다. 새 asset 등록 전부터 실행 중이던 세션이면 한 번 재기동해 asset manifest를 갱신한 뒤 다시 `r`을 적용한다. Skills 앱에서 데스크톱, 태블릿, 모바일 경로의 세 채널 로고를 확인한다.

**Step 4: Commit with Angular convention**

```bash
git commit -m "feat(skills): show brand logos in channel avatars"
```
