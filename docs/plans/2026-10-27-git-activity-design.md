# Git activity design

**Goal:** Restyle the portfolio's git app using the supplied Kevser habit tracker reference: black canvas, pill controls, seven date tiles, rounded tinted cards and contribution squares.

**Architecture:** Keep GitHubApp, the existing README assets, external launcher and live contributions loader. Scope a dark theme to the git content. Arrange a purple profile summary, green live activity card, yellow tech stack and orange/cyan account cards. Preserve the complete scrollable annual calendar; date tiles select actual daily counts without an extra request or fabricated activity.

**Tech stack:** Existing Flutter widgets only; no new dependencies or backend changes.

1. Add a contribution-date selection test using sparse real-date fixtures. Run it before implementation to verify the missing behavior.
2. Restyle `lib/portfolio/apps/system_apps.dart` and `lib/portfolio/widgets/github_contributions.dart`; retain loading, retry, refresh, safe launch feedback and all account destinations.
3. Update the existing content-order assertion for the new activity-before-tech-stack layout. Verify phone, tablet, desktop and enlarged text with the existing tests and a local browser preview.
4. Run `flutter analyze`, the GitHub/content/mobile regression tests and a production web build. Inspect the final diff and record results.

**Review corrections:** Keep external-link failure feedback outside the scroll content so it is immediately visible. Perform date-strip arithmetic in UTC so daylight saving transitions cannot skip a calendar day. The mobile navigation header uses the same dark appearance as the git content.

**Verification:** 136 relevant widget tests pass, including mobile navigation and desktop regression coverage. All nine contribution tests also pass under `TZ=America/New_York`, including the March 8 daylight saving transition. Large text remains selectable at 320px in the same scrollable host used by the app. `flutter analyze` and `dart run tool/build_web.dart` pass. Browser verification used live contribution data and confirmed that selecting another date updates its activity count. No deployment was performed.
