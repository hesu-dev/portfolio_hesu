# Resume readability implementation plan

**Goal:** Apply the supplied document references to the six-section introduction and existing career history.

**Architecture:** Keep canonical content shared by the screen and printable portfolio. Render numbered sections with headings and bullet points; reuse one timeline entry in About and Profile. Preserve education, navigation and existing source data.

**Tech Stack:** Flutter widgets, Dart, existing pdf package and HTML print fallback. No new dependencies.

1. Update existing content/layout checks to require separate introduction headings and visible role/company/date hierarchy; confirm they fail on the old presentation.
2. Add a small numbered-section parser with plain-text fallback; put canonical introduction sentences on explicit bullet lines.
3. Render green section headings with rules, indented bullets, responsive spacing and accessible text.
4. Use indigo timeline markers for career entries in About and Profile, preserving existing profile controls and education links.
5. Apply the section hierarchy to PDF and HTML, run focused widget/parser/print tests and analyzer.
6. Rebuild the localhost preview and verify the actual mobile introduction and career pages; capture screenshots for the user.
