# Margins feature scorecard

Reviewed 16 October 2026. Backend deployment is deferred at the owner’s request. The latest readiness fixes are saved separately for review; no backend service or paid hosting was started. **Goal remains open:** every feature must reach at least 8/10 with evidence. Preparing a backend does not prove a deployed community or phone notifications.

[Open Margins](https://pragalbhshandilya.github.io/margins/) · [Finish backend setup](BACKEND-SETUP.md)

## How ratings work

A product/engineering judgment, not a claim of formal certification: core behavior (4 points), usability (2), reliability/data safety (2), and end-to-end verification (2). A feature with a missing essential service or unverified production delivery cannot pass 8, even when unit tests pass. Baselines combine original-source review and live browser checks; final ratings use the revised candidate tests described below.

| Feature | Before | Current | Evidence and improvements |
|---|---:|---:|---|
| Add book, movie, family/friend quotes | 6 | 8.5 | Browser-created movie and family quotes; channel book quote saved. Whitespace and length validation, optional author/context, clear source categories. |
| Edit, remove, undo | 1 | 8.5 | Browser edited context, removed quote, restored it using Undo. Confirmation preserves accidental removals; published quotes require unpublishing first. |
| Search, category filters, sorting | 6 | 8 | Multiword, case-insensitive cross-field search; movie filter and author sort checked in browser; empty results can clear all filters. Core tests cover combinations. |
| Favorites | 6 | 8.5 | Toggle persists; favorite collection can supply reminders. Browser favorite operation no longer changes the selected reminder quote. |
| Daily quote and rediscovery | 6 | 8 | Current device date, curated attribution, shuffle across saved/editorial words, save with duplicate prevention, source channel navigation. |
| Read/follow serious and funny channels | 3 | 8 | Three readable editorial collections with nine quotes. Browser followed Absurdly Human, opened its quotes, kept a quote, and saw followed content feed. Uncertain attribution is marked. |
| Real account creation/sign-in/profile | 1 | 6.5 | Local backend and browser signup/profile integration passed. Salted password hashes, hashed expiring sessions, rate limits, signout. **Not hosted; recovery and moderation are pre-public-launch work.** |
| Follow real readers and see shared quotes | 1 | 6.5 | Two local test accounts: explicit publication, discovery, following, feed, unfollow tests passed; private account fields do not leak. **Needs deployed, two-device verification.** |
| Publish/unpublish individual quotes | 1 | 6.5 | Browser published a quote and reader saw its public count; API tests cover edit/unpublish and cross-account ownership. Private library never auto-publishes. **Needs deployed verification.** |
| Design cards with presets or own photos | 4 | 8 | Forest, sea, paper, own JPEG/PNG/WebP; upload is validated/resized. Browser uploaded a personal-image fixture, saved it and verified it survived reload. Photo remains local. |
| Save/share quote cards | 1 | 8 | Browser downloaded a real 1080×1350 PNG and copied exact quote/author to clipboard; image visually inspected. Quote-card → Moments flow selects the exact quote. Photo-load failures fall back explicitly. |
| Random in-app moments and quiet hours | 2 | 8 | Stable quote IDs, source pool, 1–3 randomized slots, quiet-window validation, next-delivery status, pause, persistence. **Real automatic browser reminder arrived** during a short-window test. Core tests cover skipped windows, next-day planning and duplicate slot prevention. |
| Background/device notifications | 1 | 6 | Durable jobs, IANA timezones/DST, Web Push encryption, bounded retry, expiry cleanup, pause/signout, safe subscription endpoints. Backend delivery tested with an injected sender. **Not a real browser push/phone delivery test; hosting, permission and app-closed acceptance remain required.** |
| Export, merge/import and restore | 1 | 8.5 | Real JSON download inspected: quotes, saved photo and paused schedule present. Browser merged backup, prevented duplicates, rejected unsupported file, restored profile/card while keeping reminders paused. Existing quotes are never replaced by import. |
| Persistence, migration, recovery | 4 | 8 | Actual adapter tests simulate blocked/quota-limited storage and corrupt data. Original unreadable data is quarantined/exportable. Legacy quotes migrate without losing IDs/favorites. No claim of automatic cross-device private-library sync. |
| Apple-inspired book feel, phone layout, navigation | 7 | 8 | Warm paper, serif quote typography, quiet green, compact cards. Browser reviewed at 390×844. Responsive bottom navigation, labelled forms, dialog semantics, focus styles, reduced-motion support and larger tap targets. Not a full assistive-technology certification. |
| Public share link and source delivery | 8 | 8 | GitHub Pages app and GitHub source available. Frontend needs no account; production community waits for the owner's backend setup. |

## Verification record

### Automated

`node --test tests/*.test.mjs` — **37 passed, 0 failed** on bundled Node 24.19.0. JavaScript syntax checks passed.

- `tests/core.test.mjs`: quote validation, identity-preserving edits, legacy migration, malformed imports, combined search/filter, reminder validation, random planning, midnight/slot behavior, selected-quote regression, channel pools and deleted quote recovery.
- `tests/storage.test.mjs`: real persistence adapter save/load, corruption quarantine, blocked storage, quota failure, migration persistence.
- `tests/notifications.test.mjs`: delayed and failed remote sign-out, absent sessions, bounded service-worker readiness, and propagation of errors.
- `tests/backend.test.mjs`: health/CORS, signup/signin/expiry, hashes, public quote lifecycle, ownership isolation, discovery/follow/feed, safe profile handling, push input protection, quiet hours, success/retry/expired-subscription delivery, signout revocation, timezone/DST planning, private-file protection. A real SQLite restart preserves accounts, sessions, quotes, follows, jobs and Web Push keys. The server serves every imported browser module needed for a hosted app.

Push-sender tests prove server behavior, not actual OS notification delivery.

### Browser/manual

- Additional readiness test: stopped the local backend while signed in. Sign-out retained credentials for retry and displayed failure. Pause displayed that server delivery was unconfirmed instead of claiming success. Restarted the backend; retrying Pause succeeded and cleared the warning; sign-out then received server confirmation. Reconnecting the same address preserved the existing sign-in.

- Original live bug reproduced: changing a favorite reset the selected quote in Moments.
- Revised local app: whitespace rejected; family quote created; context edited; favorite toggled; multiword search and no-results reset checked; quote removed/restored; movie quote created; source filter/sort checked.
- Followed/read funny channel; kept channel quote; selected family quote for reminder; favorite change did not reset selection.
- Invalid quiet hours rejected; paused state persisted; an automatic reminder arrived in its chosen time window.
- Own photo uploaded and persisted across reload. Real PNG export inspected; copy quote verified against clipboard text; use-in-moments flow verified.
- Real backup JSON inspected. Merge, duplicate prevention, invalid import, and optional full card/profile restore verified.
- Connected local backend; created test account; edited public profile; published a quote. A second local account published a quote; first account discovered/followed it and saw its feed entry.
- Phone-width layout reviewed at 390×844; desktop navigation and modal flows exercised.

## Deferred acceptance gates (owner will deploy later)

1. Deploy the prepared backend to an always-on HTTPS service with persistent storage using [the setup guide](BACKEND-SETUP.md). Review hosting cost before deployment.
2. On two separate devices, connect that same backend, create accounts, publish intended quotes, and verify follow/unfollow/feed changes and private-quote exclusion.
3. On an opted-in real phone, receive a moment with the app closed inside quiet hours. Verify notification denial, pause, signout and host restart. iOS requires a Home Screen web app.
4. Resolve any failures, then update the below-8 scores from actual deployed evidence. Do not automatically promote them because setup instructions exist.

The goal is deliberately **not marked complete** while these gates remain.
