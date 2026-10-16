# Native iPhone feature scorecard

16 October 2026. Goal remains open. Ratings use core behavior (4), usability (2), data safety/reliability (2), and end-to-end evidence (2). A missing essential service or unverified delivery keeps a feature below 8. Web ratings in the repository root do not automatically apply to this native app.

| Feature | Current /10 | Evidence / remaining acceptance |
|---|---:|---|
| Add quotes and attribution | 7 | Device Hub created a book quote with author/context. Blank/length validation has core coverage; movie/life selection and keyboard-visible layout still needed. |
| Edit quotes | 7 | Normal typing saved changed text and preserved attribution/favorite. Accessibility setValue alone changed UITextView display without updating the binding, so it is not valid input evidence. Editor title visibly truncated; shortened to New quote/Edit quote, rebuilt visual check passed. Edited text, attribution and favorite survived app replacement/relaunch. |
| Favorites | 8 | Runtime toggle, edit preservation and rebuilt relaunch passed. Favorites filter showed the quote; unfavoriting removed it immediately, then All retained the saved quote. |
| Remove / undo | 8 | Runtime confirmation dismissed without loss; confirming removed only the disposable QA quote, count became zero, and Undo restored the edited text, author, context and category. |
| Search / filters / sorting | 7 | Books excluded the life quote, From life included it, Favorites membership reacted immediately. Core tests pass; runtime search and multi-quote sorting pending. |
| Rediscovery / keeping quotes | 7 | Native hero renders saved text and updates after edit. Shuffle and duplicate-save runtime acceptance pending. |
| Serious/funny channels | 6 | Bundled collections and pool tests; follow/read/unfollow runtime acceptance pending. |
| Card design / personal photos | 6 | Implementation compiles; runtime photo, long-text and image rendering pending. |
| Image/text sharing | 5 | Native share implementation; actual export/share acceptance pending. |
| Random moments / quiet hours | 6 | Random slots, caps, quiet hours and DST core tests; runtime settings/permission/pending queue acceptance pending. |
| App-closed notifications / tap routing | 5 | Native local notification implementation; actual delivery, pause and correct tap target pending. |
| Backup / merge / web migration | 7 | Core roundtrip, merge, malformed input and web migration tests pass; file-picker/export runtime pending. |
| Persistence / corruption recovery | 6 | Edited quote, attribution and favorite survived a rebuilt app relaunch. Corruption/recovery runtime pending. |
| Accounts / sign-in / Keychain | 4 | Client prepared; hosted service and runtime account/Keychain checks deferred by owner. |
| Following readers / shared feed | 4 | Client prepared; two-account hosted acceptance deferred by owner. |
| Publish / unpublish | 4 | Client prepared; hosted ownership/lifecycle acceptance deferred by owner. |
| Native design / navigation / accessibility | 7 | Home, Library, editor visually inspected on iPhone 18 Pro / iOS 27; native tab navigation works. Large text, VoiceOver, smaller phone and keyboard layout pending. |
| Project/source delivery | 8 | Draft PR #2 contains editable Xcode project, shared scheme, setup and CI. Local iPhone build and 12 core tests passed; simulator launch verified via Xcode/Device Hub. |

## Session evidence

Created disposable quote `QA: Small steps make a good beginning.`, author `QA Reader`, context `Simulator acceptance`. Favorited it. Normal keyboard replacement to `QA: A verified edit, one word at a time.` saved successfully; hero and row both displayed the edited text, attribution and filled heart. No real personal quote was modified. Test quote remains in the isolated simulator for further persistence/delete acceptance.

The first accessibility-setValue edit did not update the 38-character counter and did not persist; normal keyboard input updated the counter and saved. Do not classify this automation-only path as a confirmed user-facing save defect.

No claim that all features meet 8/10. No paid hosting, backend deployment or physical phone installation performed.

## Category, favorite and removal acceptance

Changed the disposable book quote to From life through the native picker; saved row and hero both changed category. Library Books filter showed a contextual empty state, From life showed the quote, Favorites showed it, and unfavoriting removed it from Favorites without deleting it. Returned to All. Removal popover dismissed by tapping outside retained the quote; confirming Remove quote produced zero items and Undo removal restored its exact edited text, author, context and life category.

Found the one-item count read “1 words kept” and counted quotes rather than words. Changed it to singular/plural “1 quote kept” / “N quotes kept”; unsigned iPhone rebuild succeeded. Xcode relaunched the simulator app; a later Device Hub reconnect timed out twice, so the revised count visual acceptance remains pending.

## Search, sorting and count follow-up

Device Hub reconnected after starting the stopped simulator. Opened installed Margins from Spotlight. Restored life quote remained present and Library showed the corrected “1 quote kept” label. Search was not visible in the default Library view and a pull-down attempt did not reveal it; changed searchable placement to an always-visible navigation-bar drawer. Rebuilt visual/search entry acceptance is still pending.

13 portable core tests pass, including new explicit chronological sorting in both directions, mixed life/movie category and favorite constraints, cross-field case-insensitive whitespace/multiword matches, rejection of terms spread across separate quotes, and verification that search does not reorder stored data. This strengthens algorithm evidence without substituting for native search/sort interaction checks.
