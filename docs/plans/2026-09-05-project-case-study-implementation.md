# Project Case Study Detail Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild each project detail as a responsive, accessible case study while preserving Finder navigation and the existing external-link behavior.

**Architecture:** Extend the immutable portfolio project model with optional highlights, architecture nodes, and ordered case-study sections. Render those fields inside the existing Projects detail ListView so navigation, launch state, and mobile bottom insets stay unchanged. Keep all new collections immutable and searchable.

**Tech Stack:** Flutter, Dart, Material 3, flutter_test

---

### Task 1: Extend the project content model

**Files:**
- Modify: `lib/portfolio/data/portfolio_data.dart`
- Test: `test/portfolio/portfolio_data_test.dart`

**Step 1: Write the failing tests**

Add tests for section labels/order, derived year, defensive copies of highlights/sections/architecture nodes, and inclusion of new content in `allSearchableText`.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/portfolio_data_test.dart`
Expected: FAIL because the case-study value types and project fields do not exist.

**Step 3: Write the minimal implementation**

Add `PortfolioProjectSectionKind`, `PortfolioProjectSection`, and `PortfolioProjectArchitecture`; extend both project constructors with optional immutable fields and add a derived year getter. Include every new textual value in `allSearchableText`.

**Step 4: Run tests to verify they pass**

Run: `flutter test test/portfolio/portfolio_data_test.dart`
Expected: PASS.

### Task 2: Render the responsive case-study hierarchy

**Files:**
- Modify: `lib/portfolio/apps/projects_app.dart`
- Test: `test/portfolio/projects_finder_app_test.dart`

**Step 1: Write the failing widget tests**

Inject a complete case-study fixture and assert the order and content of year/title, existing action key, hash-prefixed technology tags, architecture, highlights, and all seven narrative labels. Test desktop row layout, compact stacked layout, 200% text scaling, and scrollability without overflow.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/projects_finder_app_test.dart`
Expected: FAIL because the new detail keys and sections are not rendered.

**Step 3: Write the minimal implementation**

Reorder `_SelectedProjectDetail`, preserve `_ProjectActions` callback/state contracts, and add private responsive architecture, highlights, metadata, and narrative widgets. Keep the existing detail scroll and bottom inset.

**Step 4: Run tests to verify they pass**

Run: `flutter test test/portfolio/projects_finder_app_test.dart`
Expected: PASS.

### Task 3: Populate verified portfolio case-study content

**Files:**
- Modify: `lib/portfolio/data/portfolio_data.dart`
- Test: `test/portfolio/portfolio_data_test.dart`

**Step 1: Write the failing content assertions**

Assert that every published project has at least a work section and highlights, ReadingLog exposes its app/extension flow, and PersonaChat is explicitly identified as a design-stage project with architecture and the documented 19-posting measurement.

**Step 2: Run tests to verify they fail**

Run: `flutter test test/portfolio/portfolio_data_test.dart`
Expected: FAIL because project case-study content is still empty.

**Step 3: Add only evidence-backed content**

Map existing project descriptions to work sections, add link- and document-backed highlights, and populate detailed ReadingLog/PersonaChat sections without inventing business metrics. Leave unsupported section kinds absent.

**Step 4: Run tests to verify they pass**

Run: `flutter test test/portfolio/portfolio_data_test.dart`
Expected: PASS.

### Task 4: Regression and visual verification

**Files:**
- Verify: `lib/portfolio/apps/projects_app.dart`
- Verify: `lib/portfolio/data/portfolio_data.dart`

**Step 1: Format and analyze**

Run: `dart format lib/portfolio/data/portfolio_data.dart lib/portfolio/apps/projects_app.dart test/portfolio/portfolio_data_test.dart test/portfolio/projects_finder_app_test.dart`

Run: `flutter analyze`
Expected: no issues.

**Step 2: Run the focused and full suites**

Run: `flutter test test/portfolio/portfolio_data_test.dart test/portfolio/projects_finder_app_test.dart test/portfolio/app_content_test.dart test/portfolio/projects_location_navigation_test.dart`

Run: `flutter test`
Expected: all tests pass.

**Step 3: Build and inspect the web app**

Run: `flutter build web`
Expected: exit 0. Inspect desktop and mobile detail screens for hierarchy, clipping, scrolling, and preserved link feedback.
