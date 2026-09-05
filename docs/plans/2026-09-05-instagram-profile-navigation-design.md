# Instagram-inspired mobile profile design

## Goal

Bring the phone and tablet Profile app closer to Instagram's profile hierarchy while preserving the portfolio's existing Apple shell, Reels detail, reply thread, and app-stack behavior.

## Chosen structure

On tablets, the Profile surface becomes a full-height row. A narrow icon rail sits on the left and the existing app navigation header plus scrollable profile content occupy the remaining width. The rail uses real portfolio destinations instead of decorative controls: profile home, Reels, company portfolio, email, and settings. It stays visible in both the profile feed and Reels detail. Phones keep the full-width profile content with no side rail, and desktop remains unchanged because it does not expose the Profile app.

The profile summary retains the verified portfolio statistics and biography, and adds the explicitly requested identity and actions: `민희수`, `@min_hesu`, `팔로우`, and `메시지 보내기`. Follow is a local visual toggle; Message opens the existing Mail app. No recommended-friend surface or add-person action is introduced.

Phone layouts keep the avatar and compact statistics together, followed by identity, biography, and actions. Tablet layouts use the wider Instagram-like avatar/identity arrangement alongside the rail. Action buttons fall back to a vertical layout at large text scales.

## Gallery and navigation

The career gallery card keeps its existing gallery-to-Reels behavior so career media and replies remain reachable on both phones and tablets. A separate 44-pixel outward-link action in that card opens `PortfolioAppId.projects`; a newly opened Projects app already starts at its `회사` location, so no parallel deep-link state is needed. Education remains a gallery-to-Reels entry. The tablet sidebar Reels action also opens the career Reels detail when career data exists.

## Responsive and accessible behavior

The tablet rail is 72 logical pixels wide, with a one-pixel divider and 44-pixel minimum targets. Its action list can scroll on very short screens. Every action has a Korean semantic label and a stable test key. The phone layout must not build the rail. The profile feed remains independently scrollable and continues to restore its offset after returning from Reels.

The implementation must remain overflow-free at 320×480 and at 200% text scale, in light and dark modes. The sidebar must not hide the common back/close header or the reply data below the Reels media.
