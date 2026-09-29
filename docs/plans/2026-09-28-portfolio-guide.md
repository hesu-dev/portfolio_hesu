# Floating portfolio guide

**Goal:** Add an always-available floating button that opens the supplied Korean portfolio guide on desktop, tablet, and phone. Match the user's AssistiveTouch reference with a translucent dark rounded square, white center, and concentric gray rings, keeping a 52px hit target. Allow mouse and touch dragging anywhere within the screen's safe bounds.

**Design:** Use the existing Apple colors and app artwork in a compact rounded menu above the bottom-right button. On desktop, place the button beside the Dock to avoid desktop icons; on mobile, place it above the Dock and within safe areas. Preserve the five supplied labels and route them to `introduction`, `safari`, `skills`, `github`, and `terminal` respectively. A shared Flutter `MenuAnchor` provides dismissal, scrolling, and keyboard navigation without a new dependency.

**Implementation:**
1. Add a focused shell integration test for all five destinations, menu dismissal, and narrow-screen layout.
2. Add `lib/portfolio/widgets/portfolio_guide_button.dart` and mount it at the top of both shells' visual stacks, using their existing `_openApp` callbacks.
3. Run the guide and shell tests, static analysis, and a visual preview at desktop and mobile sizes.
4. Keep the button's dragged position when opening apps, clamp it after viewport changes, and distinguish dragging from a tap that opens the menu. Limit gesture handling to the button so underlying content remains interactive.

Existing uncommitted project/content edits remain in place. This change does not create new destination content.
