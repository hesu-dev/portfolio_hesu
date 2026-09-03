# macOS / iPhone Portfolio Redesign

## Goal

Replace the currently served Flutter portfolio with a responsive Apple-inspired portfolio: a macOS desktop experience on wide screens and an iPhone home-screen experience on mobile. The interface must use only Min He-su's existing portfolio content and links.

## Product direction

The reference portfolio is useful for its desktop metaphor and depth of interaction, but its Windows styling, identity, project content, and public assets will not be copied. On viewports 820 logical pixels wide or larger, the portfolio renders as a modern macOS desktop. Narrower viewports render as an iPhone home screen instead of a reduced desktop or a “use a PC” blocker.

Both shells expose the same core apps and the same immutable portfolio data:

- About: Min He-su's introduction, experience, and education.
- Skills: Flutter/Dart, React, Java, collaboration, and design tools.
- Projects: PersonaChat, ReadingLog, Blue Mentor, IRIS, AI-Bver, and HiddenTag.
- Terminal: a small, deterministic portfolio command interpreter.
- GitHub and contact: `hesu-dev` and `hs0647@naver.com`.

No text, email address, project, or outbound link belonging to the reference site's owner may appear in the delivered app.

## Architecture

`PortfolioData` is the single source of truth for identity, biography, experience, skills, projects, and links. Responsive shell widgets consume this data without duplicating it. The root uses `LayoutBuilder` to select `MacDesktop` or `IPhoneHome` at the 820-pixel breakpoint.

The macOS shell owns a small window-manager state: open, minimized, maximized, active z-order, position, and size. Apps open from desktop icons or the Dock. Window chrome supports close, minimize, maximize/restore, focus, and title-bar dragging. The shell includes a menu bar, animated translucent Dock, Apple menu, Control Center, and notification panel. Visuals use Flutter gradients, blur, shadows, and vector/material symbols; no remote wallpaper dependency is required.

The iPhone shell uses safe-area insets, a status bar, paged-looking app grid, translucent Dock, and home indicator. Tapping an app opens a full-screen mobile surface with native-style navigation. About, Skills, Projects, Terminal, GitHub, and Mail share the same app identifiers as macOS. Closing an app returns to the home screen, and links launch externally only after an explicit tap.

## Desktop apps

- **About / Pages:** document-like biography with career and education sections.
- **Skills / Finder:** Finder sidebar and categorized skill files in list/icon views.
- **Projects / Safari:** sidebar project selector, detail report, stack chips, store/research/source links.
- **Terminal:** `help`, `whoami`, `ls`, `cat skills.md`, `git status`, `git log`, `clear`, and unknown-command feedback.
- **This Mac / Finder:** concise system-style overview of the portfolio and available apps.
- **Trash:** empty-state window.
- **GitHub / Mail:** external actions tied only to Min He-su's addresses.

## Mobile apps

The mobile About, Skills, Projects, and Terminal views keep the same information hierarchy but replace floating windows with full-screen app navigation. Project details use vertical cards and large tap targets. External GitHub, store, research, and email actions remain explicit. Landscape phones keep the iPhone shell unless the logical width crosses the breakpoint.

## Interaction and accessibility

Every icon is keyboard focusable and has a semantic label. Desktop apps open with double-click/Enter and Dock apps open with a single click. Window controls have descriptive tooltips. Motion is short and restrained; content remains usable when animations are skipped. Text contrast remains readable over blur layers, and project content scrolls independently inside its app surface.

## Error handling

The terminal never throws on unknown input and prints a helpful response. Empty or invalid project URLs are not rendered as actions. External-launch failures surface a local snackbar without changing application state. Window positions are clamped to the visible work area after resize, and a maximized window restores to its prior bounds.

## Testing

Widget tests cover responsive shell selection, identity/content safety, app opening, close/minimize/maximize behavior, Dock restoration, mobile app navigation, and project selection. Unit tests cover terminal parsing and portfolio-link filtering. `flutter analyze`, `flutter test`, and a release web build are required. The finished build is visually checked at desktop and phone viewports in a browser, including scrolling, window focus, outbound-link labels, and console errors.

## Repository safety

Existing uncommitted files and non-portfolio artifacts remain untouched. New UI code lives under `lib/portfolio/`; only the entry point, asset manifest if needed, tests, and deployment-facing metadata are changed. Legacy page files may remain in the repository but are disconnected from the application entry point, so they cannot be served or reached.
