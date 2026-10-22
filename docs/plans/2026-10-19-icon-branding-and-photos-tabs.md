# Portfolio icon, naming and Photos tabs

**Goal:** Remove the portfolio icon's baked border and padding, use `Portfolio` or `포트폴리오` in displayed names, and repair the Photos bottom navigation capsule.

1. Render the existing icon SVG with a full-canvas gradient and no outer stroke; retain the two windows. Regenerate every native PNG and Windows ICO using the existing tool. Verify blue opaque edges, original artwork, dimensions and iOS RGB output.
2. Update the shared project title, terminal prompt, Mac menu and native display names. Preserve package names, identifiers, storage keys and actual source URLs. Exercise the existing data, Safari, Files and terminal tests with the new visible names.
3. Give Library and Albums one centered capsule with matching tab geometry, selected shape and padding. Consume system bottom safe area once; verify 320/390/iPad sizes, both themes, 200% text and navigation behavior.
4. Run targeted regression tests and analysis, inspect the icon and Photos renders, then build and run the signed iPhone release. Preserve existing workspace changes and build-cache symlinks.
