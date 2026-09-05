# macOS / iPhone Portfolio Redesign

## Goal

Replace the currently served Flutter portfolio with a responsive Apple-inspired portfolio: a macOS desktop experience on wide screens, an iPadOS experience on tablet widths, and an iPhone home-screen experience on mobile. The interface must use only Min He-su's existing portfolio content and links.

## Product direction

The reference portfolio is useful for its desktop metaphor and depth of interaction, but its Windows styling, identity, project content, and public assets will not be copied. The responsive experience has three deliberate shells instead of shrinking one layout:

- 1024 logical pixels and wider: modern macOS desktop.
- 600–1023 logical pixels: iPadOS home screen and tablet app surfaces.
- Below 600 logical pixels: iPhone home screen and phone app surfaces.

Both shells expose the same core apps and the same immutable portfolio data:

- About: Min He-su's introduction, experience, and education.
- Skills: Flutter/Dart, React, Java, collaboration, and design tools.
- Projects: PersonaChat, ReadingLog, Blue Mentor, IRIS, AI-Bver, and HiddenTag.
- Terminal: a small, deterministic portfolio command interpreter.
- GitHub and contact: `hesu-dev` and `hs0647@naver.com`.

No text, email address, project, or outbound link belonging to the reference site's owner may appear in the delivered app.

## Architecture

`PortfolioData` is the single source of truth for identity, biography, experience, skills, projects, and links. Responsive shell widgets consume this data without duplicating it. The root uses `LayoutBuilder` to select `MacDesktop`, `IPadHome`, or `IPhoneHome` at the 1024- and 600-pixel breakpoints.

The macOS shell owns a small window-manager state: open, minimized, maximized, active z-order, position, and size. Apps open from desktop icons or the Dock. Window chrome supports close, minimize, maximize/restore, focus, and title-bar dragging. The shell includes a menu bar, animated translucent Dock, Apple menu, Control Center, and notification panel. Visuals use Flutter gradients, blur, shadows, and vector/material symbols; no remote wallpaper dependency is required.

The iPad and iPhone shells use safe-area insets, status bars, app grids, translucent Docks, and home indicators. The iPad layout uses a wider grid, larger widgets, and tablet-sized app cards; the iPhone uses a compact four-column grid and full-screen app surfaces. About, Skills, Projects, Terminal, GitHub, and Mail share the same app identifiers as macOS. Closing an app returns to the home screen, and links launch externally only after an explicit tap.

## Desktop apps

- **About / Pages:** document-like biography with career and education sections.
- **Skills / Finder:** Finder sidebar and categorized skill files in list/icon views.
- **Projects / Safari:** sidebar project selector, detail report, stack chips, store/research/source links.
- **Terminal:** `help`, `whoami`, `ls`, `cat skills.md`, `git status`, `git log`, `clear`, and unknown-command feedback.
- **This Mac / Finder:** concise system-style overview of the portfolio and available apps.
- **Trash:** temporary-item list, confirmation dialog, and session-only filled/empty visual state shared with launcher artwork.
- **GitHub:** profile action plus three repository cards that open their verified GitHub URLs.
- **Mail:** compose surface with recipient, subject, body, and an explicit `mailto:` send action.

## iPad apps

The iPad shell presents a spacious home grid and a floating Dock. Apps open as large rounded tablet surfaces with persistent navigation where useful. Photos provides a populated responsive library and album filters. The shell remains recognizably iPadOS in both portrait and landscape orientations.

## iPhone apps

The iPhone About, Skills, Projects, and Terminal views keep the same information hierarchy but replace floating windows with full-screen app navigation. Project details use vertical cards and large tap targets. External GitHub, store, research, and email actions remain explicit. Landscape phones keep the iPhone shell unless the logical width crosses the tablet breakpoint.

## Interaction and accessibility

Every icon is keyboard focusable and has a semantic label. Desktop apps open with double-click/Enter and Dock apps open with a single click. Window controls have descriptive tooltips. Motion is short and restrained; content remains usable when animations are skipped. Text contrast remains readable over blur layers, and project content scrolls independently inside its app surface.

## Error handling

The terminal never throws on unknown input and prints a helpful response. Empty or invalid project URLs are not rendered as actions. External-launch failures surface a local snackbar without changing application state. Window positions are clamped to the visible work area after resize, and a maximized window restores to its prior bounds.

## Testing

Widget tests cover responsive shell selection, identity/content safety, app opening, close/minimize/maximize behavior, Dock restoration, mobile app navigation, and project selection. Unit tests cover terminal parsing and portfolio-link filtering. `flutter analyze`, `flutter test`, and a release web build are required. The finished build is visually checked at desktop and phone viewports in a browser, including scrolling, window focus, outbound-link labels, and console errors.

## Repository safety

Existing uncommitted files and non-portfolio artifacts remain untouched. New UI code lives under `lib/portfolio/`; only the entry point, asset manifest if needed, tests, and deployment-facing metadata are changed. Legacy page files may remain in the repository but are disconnected from the application entry point, so they cannot be served or reached.
