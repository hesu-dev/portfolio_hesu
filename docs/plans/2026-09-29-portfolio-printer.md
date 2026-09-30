# Portfolio Printer Implementation Plan

**Goal:** Open a PDF viewer from a desktop printer shortcut, with one document containing the existing resume, profile introduction, and all projects.

**Architecture:** Open a browser tab synchronously, then generate an A4 PDF from the existing portfolio data using the Dart `pdf` package and bundled Korean fonts. The browser PDF viewer provides pagination, zoom, save, and print. Browsers without an inline PDF viewer, or failed PDF generation, receive a printable HTML document instead. Blocked popups produce an actionable error.

**Tech Stack:** Flutter/Dart, `pdf`, existing `package:web`, Nanum Gothic (OFL), HTML/CSS fallback.

1. Add HTML and PDF document renderers with tests for content, safe links, Korean fonts, and long-document pagination. Preserve original draft labels in project content.
2. Add the desktop printer icon with mouse and keyboard activation, keeping the existing app grid and Dock unchanged.
3. Use the profile biography for the introduction, as selected by the user.
4. Run the full tests, static analysis, and web build. Inspect the PDF pages and browser flow.
5. Commit all changes using the AngularJS commit convention and push to `origin/main`, as requested.

The user requested the PDF viewer flow after the initial HTML implementation. pdfcn is React-specific; its native browser PDF preview behavior is reproduced without a React application.
