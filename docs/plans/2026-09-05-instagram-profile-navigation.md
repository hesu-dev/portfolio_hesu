# Instagram-inspired mobile profile implementation plan

**Goal:** Add the requested Instagram-inspired profile identity/actions on phone and tablet, a tablet-only functional side rail, and a career-to-company portfolio link.

**Architecture:** Reuse the existing `PortfolioAppContent.onOpenApp` callback so Profile can push Mail, Projects, and Settings through the same mobile app stack. Keep all profile-specific presentation and local follow state in `ProfileApp`; do not alter unrelated portfolio data models.

**Tech stack:** Flutter, Material widgets, existing Apple theme primitives, Flutter widget tests.

### Task 1: Specify the responsive profile contract

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`

1. Add failing phone and tablet tests proving the sidebar is tablet-only, plus requested name/handle, follow and message actions, and absence of recommended friends.
2. Add failing action tests for follow state, Mail routing, career-to-company routing, and Reels access from the sidebar.
3. Run the focused profile test file and confirm the new assertions fail for the expected missing UI.

### Task 2: Route Profile actions through the existing app stack

**Files:**
- Modify: `lib/portfolio/apps/portfolio_app_content.dart`
- Modify: `lib/portfolio/apps/profile_app.dart`

1. Add an optional `onOpenApp` callback to `ProfileApp` and pass it from `PortfolioAppContent`.
2. Add small handlers for Mail, Projects, Settings, feed reset, and first available Reels detail.
3. Keep standalone Profile behavior safe when the callback is absent.

### Task 3: Build the Instagram-inspired responsive surface

**Files:**
- Modify: `lib/portfolio/apps/profile_app.dart`

1. Wrap the tablet header/content column in a row with a fixed side rail while leaving phone full-width.
2. Implement functional, accessible rail items with selected-state styling and short-height scrolling.
3. Add `@min_hesu`, follow state, and Message controls to the summary.
4. Use narrow and wide summary arrangements and stack controls for high text scale.
5. Keep the career card body connected to Reels and add a separate 44-pixel link action that opens Projects; education continues to open Reels.

### Task 4: Preserve Reels and responsive regressions

**Files:**
- Modify: `test/portfolio/profile_app_test.dart`

1. Keep phone career-detail coverage through the gallery card and cover the tablet Reels sidebar action separately.
2. Keep education gallery tests and all like, reply, back, scroll restoration, pointer, light/dark, and 200% scale coverage passing.
3. Verify Projects opens at `회사`, closes back to Profile, and Mail/Settings stack correctly.

### Task 5: Verify and commit

**Files:**
- Verify: `lib/portfolio/apps/profile_app.dart`
- Verify: `lib/portfolio/apps/portfolio_app_content.dart`
- Verify: `test/portfolio/profile_app_test.dart`

1. Format only files changed for this feature.
2. Run the focused profile and projects navigation tests.
3. Run targeted static analysis and the wider portfolio test suite if no unrelated dirty-worktree failure blocks it.
4. Inspect phone and tablet layouts in the local web build.
5. Commit only this feature's files as separate Korean Angular-style feature, test, and documentation commits.
