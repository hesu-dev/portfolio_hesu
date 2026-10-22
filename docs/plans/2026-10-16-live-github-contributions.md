# Live GitHub contributions

**Goal:** Fetch the current hesu-dev profile contribution calendar whenever Git is opened, rather than displaying only the 2026-09-28 asset.

**Design:** Request the public profile calendar through github-contributions-api.jogruber.de (CORS supported). Explicit open/refresh requests use Cache-Control: no-cache; ordinary rebuilds never fetch. Convert validated dates/counts/levels into the existing calendar shape. Never ship authentication tokens. The existing GraphQL snapshot remains a dated offline fallback, clearly labelled as saved data when the live request fails.

**Implementation:** Promote the already-installed http dependency to a direct dependency; add one loader/normalizer, refresh action and timestamp UI; remount the Git window only on an explicit desktop open/restore. Allow network client access in native release builds. Keep the existing build-time snapshot refresh.

**Verification:** Loader tests cover normalization, fresh requests and fallback; widget tests cover manual retry and timestamps; desktop regression covers restore; smoke-test real browser CORS and current calendar dates. GitHub upstream aggregation can lag even after a fresh response.

**Visibility:** Live data reflects only the publicly visible profile, so it can differ from the authenticated snapshot containing private contributions. Show the live scope and saved private scope explicitly, without embedding credentials in the app.

**Result:** 85 relevant tests pass, including stable calendar height while a manual refresh is pending. Static analysis and entitlement validation pass. The local web app successfully fetches the current calendar through browser CORS.

**Follow-up:** Hide timestamps and the public-profile caption at the user's request. The user chose GitHub's Private contributions visibility setting for hesu-dev so the same automatic loader can include anonymized private activity in the combined calendar without an authentication server. Continue to distinguish saved fallback data on network errors. The authenticated fallback snapshot was refreshed on 2026-10-16.

**Follow-up verification:** Enabled Private contributions for the user-confirmed hesu-dev account and verified the checked setting. An unauthenticated no-cache API request returned 3,724 contributions, matching the authenticated calendar; previously it returned 659. The 13 relevant tests and static analysis pass after removing the timestamp.
