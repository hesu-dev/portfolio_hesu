# Education Pixel Study Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 교육 게시물을 열 때 경력과 동일한 미디어 슬롯에서 새 투명 캐릭터 스프라이트와 코드 기반 도서관·능력치 UI로 구성된 반복 학습 애니메이션을 표시한다.

**Architecture:** 새 `EducationPixelStudy`가 하나의 반복 타임라인과 `CustomPainter`를 소유한다. 캐릭터만 투명 PNG 스프라이트에서 그리고, 21세기 도서관 컴퓨터실·모니터 미세 동작·`FLUTTER/DART/UX/SOLVE` 순차 상승 HUD는 픽셀 스냅된 코드 드로잉으로 유지한다. 프로필 overlay는 history kind를 미디어 종류로 변환해 기존 경력 러너와 새 교육 장면을 동일 슬롯에 선택적으로 삽입한다.

**Tech Stack:** Flutter, Dart, `dart:ui`, flutter_test, built-in ImageGen

---

### Task 1: 교육 장면의 데이터·자산 계약

**Files:**
- Create: `assets/sprites/education_student_study.png`
- Create: `lib/portfolio/widgets/education_pixel_study.dart`
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Write the failing contract tests**

`profile_app_test.dart`에 새 위젯 import와 다음 순수 계약을 추가한다.

```dart
test('교육 장면은 네 능력치를 정해진 순서로 올린다', () {
  expect(EducationPixelStudy.statLabels, <String>[
    'FLUTTER',
    'DART',
    'UX',
    'SOLVE',
  ]);
  expect(EducationPixelStudy.activeStatIndexFor(0.16), 0);
  expect(EducationPixelStudy.activeStatIndexFor(0.34), 1);
  expect(EducationPixelStudy.activeStatIndexFor(0.52), 2);
  expect(EducationPixelStudy.activeStatIndexFor(0.70), 3);
  expect(EducationPixelStudy.activeStatIndexFor(0.90), -1);
});

test('교육 캐릭터는 별도 투명 스프라이트 자산을 사용한다', () async {
  expect(
    EducationPixelStudy.studySpriteAsset,
    'assets/sprites/education_student_study.png',
  );
  final asset = await rootBundle.load(EducationPixelStudy.studySpriteAsset);
  expect(asset.lengthInBytes, greaterThan(0));
});
```

**Step 2: Run tests to verify RED**

```bash
flutter test test/portfolio/profile_app_test.dart --plain-name '교육 장면은 네 능력치를 정해진 순서로 올린다'
```

Expected: FAIL because `EducationPixelStudy` does not exist.

**Step 3: Generate the transparent character sheet**

Use built-in ImageGen with the existing career sprite as an identity/style reference, not as an edit target. Generate a transparent 4×2 sheet containing eight aligned seated study frames: alternating typing hands, monitor reading, note writing, page turn, and blink. Require the same brown ponytail, black glasses, light skin, navy outfit, crisp pixel edges, identical desk-seat anchor, no environment, no text, no glow, no watermark. Save the accepted result as `assets/sprites/education_student_study.png`.

**Step 4: Add the minimal public contract**

Create `EducationPixelStudy` with:

```dart
static const studySpriteAsset =
    'assets/sprites/education_student_study.png';
static const statLabels = <String>['FLUTTER', 'DART', 'UX', 'SOLVE'];
static int activeStatIndexFor(double progress) { /* deterministic windows */ }
```

Keep scene drawing private. Decode the PNG with a bounded target width and nearest-neighbor filtering.

**Step 5: Run tests to verify GREEN**

Run the two new contract tests and confirm both pass.

**Step 6: Commit**

```bash
git add assets/sprites/education_student_study.png lib/portfolio/widgets/education_pixel_study.dart test/portfolio/profile_app_test.dart
git commit -m "feat(profile): add education study sprite contract"
```

### Task 2: 반복 학습 painter와 접근성

**Files:**
- Modify: `lib/portfolio/widgets/education_pixel_study.dart`
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Write failing widget tests**

교육 장면 위젯을 단독으로 고정 크기에 렌더해 다음을 검증한다.

- `Semantics(image: true)`의 한국어 장면 설명
- `RepaintBoundary`와 하나의 `CustomPaint`
- 애니메이션 허용 상태에서 733ms 뒤 RGBA 바이트가 달라짐
- 동작 줄이기 상태에서 같은 시간이 지나도 RGBA 바이트가 같고 ticker가 남지 않음
- 320×258과 714×288에서 예외·overflow 없음

**Step 2: Run tests to verify RED**

Expected: painter, semantics, and timeline are missing.

**Step 3: Implement the pixel scene**

144 단위 가상 캔버스에서 다음 순서로 그린다.

1. 라이트·다크 전용 벽과 창문 조명
2. 후경 책장과 반복되는 컴퓨터 좌석
3. 전경 책상, 모니터, 키보드, 스탠드와 충전 포트
4. 새 스프라이트의 현재 학습 프레임
5. 상단 안전 영역의 네 능력치 HUD와 활성 행 `+1`
6. 사이클 말미의 `SESSION COMPLETE`
7. 기존 하단 정보와 오른쪽 액션을 위한 scrim

모든 사각형 좌표를 정수로 스냅하고 `Paint.isAntiAlias = false`, sprite paint의 `FilterQuality.none`을 사용한다. controller를 painter의 `repaint`에 직접 전달해 매 프레임 widget rebuild를 피한다. 스프라이트 로딩 실패 시 `FlutterError.reportError` 후 배경·HUD는 계속 렌더한다.

**Step 4: Implement reduced motion and disposal**

`MediaQuery.disableAnimationsOf`가 true이면 controller를 멈추고 능력치와 공부 포즈가 모두 보이는 결정적 진행률에 고정한다. controller, decoded image, cached `TextPainter`를 dispose한다.

**Step 5: Run tests to verify GREEN**

Run the focused widget tests and confirm deterministic frame behavior.

**Step 6: Commit**

```bash
git add lib/portfolio/widgets/education_pixel_study.dart test/portfolio/profile_app_test.dart
git commit -m "feat(profile): animate education study session"
```

### Task 3: 교육 상세에 동일 크기 장면 연결

**Files:**
- Modify: `lib/portfolio/apps/profile_app.dart`
- Modify: `test/portfolio/profile_app_test.dart`

**Step 1: Replace the obsolete empty-media test with failing integration tests**

교육 카드를 연 뒤 다음을 검증한다.

```dart
final study = find.byKey(const Key('profile-education-pixel-study'));
expect(study, findsOneWidget);
expect(
  tester.getRect(study),
  tester.getRect(find.byKey(const Key('profile-reel-media-slot'))),
);
expect(find.byKey(const Key('profile-career-pixel-runner')), findsNothing);
```

같은 iPhone/iPad 시나리오에서 경력과 교육 media rect가 동일한지도 검사한다. 기존 좋아요·댓글·공유·답글·뒤로가기 계약은 유지한다.

**Step 2: Run integration tests to verify RED**

Expected: Education media slot still has no child.

**Step 3: Refactor media selection minimally**

`_ProfileReelOverlay`의 `showCareerRunner` boolean을 private media enum으로 바꾼다.

```dart
enum _ProfileHistoryMedia { career, education }
```

경력은 기존 `CareerPixelRunner`, 교육은 `EducationPixelStudy`를 같은 keyed `ColoredBox` child로 삽입한다. 컬러 미디어가 있는 두 종류 모두 overlay foreground를 흰색으로 사용한다.

**Step 4: Update shared test helpers**

Education에 `CustomPaint`/스프라이트가 없다고 가정한 assertions만 제거한다. 가짜 소셜 지표 금지, action rail 안전 영역, reply thread, 텍스트 확대, light/dark, 스크롤 계약은 유지한다.

**Step 5: Run tests to verify GREEN**

```bash
flutter test test/portfolio/profile_app_test.dart
```

**Step 6: Commit**

```bash
git add lib/portfolio/apps/profile_app.dart test/portfolio/profile_app_test.dart
git commit -m "feat(profile): show pixel study scene for education"
```

### Task 4: 시각 QA와 전체 회귀 검증

**Files:**
- Modify if needed: `lib/portfolio/widgets/education_pixel_study.dart`
- Modify if needed: `test/portfolio/profile_app_test.dart`

**Step 1: Format and inspect the diff**

```bash
dart format lib/portfolio/apps/profile_app.dart lib/portfolio/widgets/education_pixel_study.dart test/portfolio/profile_app_test.dart
git diff --check
```

**Step 2: Run focused and full verification**

```bash
flutter test test/portfolio/profile_app_test.dart
flutter test
flutter analyze
dart run tool/build_web.dart
```

Expected: all commands exit 0 with no test, analysis, or build failures.

**Step 3: Perform visual QA**

Render and inspect at least iPhone 390×844 and iPad 834×1194 in light and dark mode. Confirm the character remains anchored at the desk, all four stats rise in sequence, the HUD avoids the camera/action rail/account overlay, pixel edges remain crisp, and the Education media rect matches Career.

**Step 4: Commit any verified refinement**

```bash
git add lib/portfolio/widgets/education_pixel_study.dart test/portfolio/profile_app_test.dart
git commit -m "fix(profile): polish education study scene"
```
