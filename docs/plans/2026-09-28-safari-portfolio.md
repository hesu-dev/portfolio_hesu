# Safari Portfolio Implementation Plan

**Goal:** Add an Apple-style Safari launcher that opens a second portfolio experience with all projects together.

**Architecture:** Reuse the existing project data in an editorial web page. Desktop and tablet use a horizontal bookmark bar above a full-width page; phone uses a bottom `모든 탭(nn)` button to open a project tab overview. The Safari surface owns selection/history; existing shells and scalable artwork provide the window and launcher.

**Tech Stack:** Flutter, existing Material widgets and CustomPainter; no new dependencies.

1. Register Safari across launcher catalogs and draw a compass icon in the existing artwork painter.
2. Test the three device navigation patterns, mixed project catalog, back/forward navigation, per-project scroll and mobile safe areas.
3. Build the responsive Safari surface and website-style project article; connect desktop/mobile app routing.
4. Update catalog expectations and run the affected Flutter tests and analyzer.
5. Review the changes, restart the local release run, and verify the Safari screen in the browser.

The current checkout contains user changes needed for the preview. Preserve them and work in place. No commit or deployment is part of this request.

## Reference report layout revision

The latest user request removes the left project navigation because bookmarks already provide project selection. Keep the report content and let it fill the available width. The 프로젝트/Safari window's default width remains 1.6 times the existing calculation, clamped to the desktop work area; preserve its existing height and other apps' geometry.

- Keep native Safari chrome, full-width bookmarks on desktop/tablet, the compact page introduction (`프로젝트` and the report description), and the existing phone tab overview. Do not show a project sidebar.
- Recompose SafariProjectPage as a main report plus right-hand stack/link cards. Keep structure, environment, and troubleshooting prominent; use existing factual data only. Do not introduce personal/company grouping.
- Use the reference's white content, subtle borders, blue titles, summary cards, and generous horizontal spacing within the existing light/dark theme.
- Collapse support cards below the report when the usable width/text scale requires it. Preserve link loading/error handling, screenshot expansion, per-project scroll, and mobile safe areas.
- Validate geometry/navigation/report tests, analyzer, and the release browser at desktop/tablet/phone widths. Preserve unrelated dirty work; no commit or deployment requested.
