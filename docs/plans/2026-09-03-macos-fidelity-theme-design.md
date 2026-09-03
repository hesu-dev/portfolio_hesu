# macOS Fidelity and Theme Design

## Goal

Refine the portfolio into a more recognizable modern Mac experience while keeping the adaptive iPadOS and iPhone shells. The desktop uses an actual locally installed macOS Sonoma wallpaper, a display notch, system-like app artwork, shared traffic controls, a dynamic Dock, a Notes-style About card, and a Slack-inspired Skills view. A new Settings app switches the entire portfolio between Light and Dark, with Light as the default and no automatic/system option.

## Visual direction

The desktop background uses still frames extracted from the locally installed 3840×2160 Sonoma Graphic Light and Dark landscape movies. The frames are encoded as compact WebP assets and selected from the active theme. The existing custom-painted aurora remains only as an image-error fallback. This satisfies the request for a real macOS background without adding the full 79 MB movie files.

The top menu bar is divided into left, center, and right safe regions. A black, centered `mac-display-notch` occupies the center and uses rounded lower corners like a MacBook display notch. At 1024 pixels and at large text scales, secondary menu labels collapse before they can overlap the notch.

The Dock becomes a borderless, near-white translucent surface with blur and shadow. Pinned launchers remain available, while unpinned running apps appear in a separate dynamic region and disappear when their window closes. A minimized app stays in the running region and restores on activation.

## App artwork

A shared `AppleAppArtwork` widget draws app-specific artwork with Flutter shapes and custom painters rather than copying Apple or Slack binary assets:

- About: split blue Finder face.
- Skills: four-color Slack-style mark.
- Projects: layered blue Finder folder.
- Terminal: dark terminal window with a `>_` prompt.
- Mail: blue gradient tile with a white envelope.
- Settings: metallic gear.
- Existing This Mac, GitHub, and Trash artwork remains compatible but gains the shared sizing and focus treatment.

The artwork is used consistently on the desktop, Dock, iPad, and iPhone. Labels and semantics continue to come from `PortfolioAppId` mappings.

## Windows and Dock lifecycle

Every desktop app window passes through `MacWindow` and one public `MacTrafficControls` component. The controls keep 28-pixel or larger hit targets and 13–14-pixel visual circles using `#FF5F57`, `#FEBC2E`, and `#28C840`. No icon or glyph appears inside the circles.

Pinned Dock launchers are About, Skills, Projects, Terminal, and Mail. Settings, This Mac, and GitHub are inserted into a running-app section only while open. Trash remains a fixed utility after the separator. Closing a dynamic app removes it; minimizing retains it; selecting it focuses or restores the existing single window.

## About and Skills applications

About combines the existing identity header and introduction into an `AboutNotesCard`. Its yellow gradient header contains a white folder outline and the label `메모`. A dotted separator leads to a white note body containing the name, English name, headline, and biography from `PortfolioData`. Career, education, and contact sections remain below the card. The content remains scrollable at compact sizes and 200% text.

Skills keeps `PortfolioData.skillGroups` as the only content source but presents it with Slack-inspired information architecture. Wide views use a narrow workspace rail, a purple channel sidebar, and a channel detail area. Compact views use a horizontally scrollable channel picker and vertically stacked message-like skill rows. No company name, channel name, or content from the reference screenshot is copied. Existing selection keys and accessibility contracts remain stable.

## Theme settings

`PortfolioThemePreference` has exactly `light` and `dark`. `PortfolioThemeController` is owned by `PortfolioApp`, defaults to Light, and updates `MaterialApp.themeMode` immediately. `ThemeMode.system` and an automatic option are not exposed. Persistence is intentionally omitted because it was not requested.

`PortfolioAppId.settings` opens a Settings application. Wide layouts show a two-pane settings surface with only one sidebar item, `화면 모드`. The detail area shows Light and Dark preview cards. Compact layouts stack the same controls. The controller is explicitly passed through the adaptive shells and shared app content so a theme change preserves open windows, active mobile apps, terminal history, and selection state.

## Testing and constraints

Tests cover default Light mode, Light/Dark switching on all form factors, absence of a system option, state preservation, actual wallpaper asset selection, notch/menu non-overlap, borderless Dock styling, dynamic running apps, glyph-free traffic controls, Notes card responsiveness, Slack-style wide/compact layouts, app artwork mappings, keyboard activation, semantics, minimum targets, and no overflow at 1440×900, 1024×700, 834×1194, 600×400, 390×844, and 320×480 with large text.

The extracted wallpaper frames are Apple-owned visual assets. The repository should include a concise non-affiliation notice and only the compressed still frames required by the requested presentation; Apple application binaries and ICNS files are not copied.
