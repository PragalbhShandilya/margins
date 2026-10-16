# Native iPhone feature scorecard

16 October 2026. Goal remains open. Ratings use core behavior (4), usability (2), data safety/reliability (2), and end-to-end evidence (2). A missing essential service or unverified delivery keeps a feature below 8. Web ratings in the repository root do not automatically apply to this native app.

| Feature | Current /10 | Evidence / remaining acceptance |
|---|---:|---|
| Add quotes and attribution | 7 | Device Hub created a book quote with author/context. Blank/length validation has core coverage; movie/life selection and keyboard-visible layout still needed. |
| Edit quotes | 7 | Normal typing saved changed text and preserved attribution/favorite. Accessibility setValue alone changed UITextView display without updating the binding, so it is not valid input evidence. Editor title visibly truncated; shortened to New quote/Edit quote, rebuilt visual check passed. Edited text, attribution and favorite survived app replacement/relaunch. |
| Favorites | 8 | Runtime toggle, edit preservation and rebuilt relaunch passed. Favorites filter showed the quote; unfavoriting removed it immediately, then All retained the saved quote. |
| Remove / undo | 8 | Runtime confirmation dismissed without loss; confirming removed only the disposable QA quote, count became zero, and Undo restored the edited text, author, context and category. |
| Search / filters / sorting | 8 | Always-visible search verified on rebuilt iPhone app. Cross-field query matched, unmatched query showed empty state, Clear restored results. Movie/life category and favorite filters passed. Two distinct quotes reversed correctly with Newest first / Oldest first. 13 core tests cover constraints and chronology. |
| Rediscovery / keeping quotes | 7 | Native hero renders saved text and updates after edit. Shuffle and duplicate-save runtime acceptance pending. |
| Serious/funny channels | 8 | Funny channel follow survived rebuilt relaunch; read/keep/duplicate prevention and saved checkmark verified. Both quotes supplied Moments previews; unfollow removed the pool. Serious channel read/follow added all three quotes to Home. Core channel pool test passes. |
| Card design / personal photos | 6 | Implementation compiles; runtime photo, long-text and image rendering pending. |
| Image/text sharing | 5 | Native share implementation; actual export/share acceptance pending. |
| Random moments / quiet hours | 7 | Frequency 3 saved while paused; native permission Allow then enabled Save reported 60 scheduled requests through 5 November. Pause disabled the switch and retained design. Missing single-quote selection rejected. 14 core tests cover quiet hours and DST conversion; app-closed delivery/denial and updated picker acceptance pending. |
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

## Rebuilt native search and sorting acceptance

Opened the current Documents/Codex/Margins/ios project in Xcode and ran it on iPhone 18 Pro. Search field visibly appears without a reveal gesture. Initial interaction overlapped app replacement and briefly showed a blank display; Xcode continued running and app returned to Home. No Margins crash report was found. Retried after launch completed: ordinary typing `QA acceptance` retained the life quote across text/author/context; `nonexistent phrase` removed all results; Clear restored the quote. Closed search.

Created a second disposable movie quote `QA: A newer movie quote for sorting.` with optional attribution omitted. Library count correctly showed `2 quotes kept`, newer movie first and earlier life second. Sort → Oldest first reversed those rows while retaining text and attribution. Search/filter/sorting raised to 8/10. Account and real notification gates remain open.

## Channel and card sharing follow-up

Followed Absurdly Human in Device Hub; Follow changed to Following. Read both humorous quotes with explicit attribution/context. Kept Oscar Wilde twice; Library increased from two to three entries with only one Wilde quote and retained attribution. The save button provided no success state, so added a disabled “Kept in library” checkmark state for already-saved channel quotes; build and rebuilt runtime check follow. Channel remains below 8 pending unfollow, feed/reminder membership and persistence acceptance.

Opened own life quote card, selected Sea, launched native Share image and chose Save to Files. The export picker showed a PNG image with the correct sea-colored card thumbnail. No export completion or external sharing is claimed; Files destination and full-size output acceptance are pending.

## Channel acceptance completed

Ran saved-state update through Xcode. Absurdly Human still Following after relaunch, and Wilde quote displayed disabled Kept in library checkmark. Moments → Followed channels previewed Wilde then the editors’ original joke. Unfollow changed Following to Follow; selecting followed channels again showed the empty guidance instead of a stale quote. Unsaved Moments preferences reset to persisted settings on tab re-entry; recorded separately as a draft-usability concern.

Read all three Quiet Chapter quotes with book/source attribution, followed that serious collection, and Home accessibility content included From your channels plus Emerson, Thoreau and Austen quotes. Existing saved Wilde copy remained independent of unfollowing. Channels raised to 8/10. This verifies bundled editorial channels; real reader/community service remains deferred and below 8.

## Quiet-hours DST control fix

Reproduced the actual prior time-control conversion with Foundation and America/New_York: midnight + nine elapsed hours displayed 10:00 on 8 March 2026 and 08:00 on 1 November 2026. The stored preference was 09:00, so the time control was misleading on both transition dates. Replaced elapsed-second conversion with a calendar wall-clock construction shared through MomentPlanner.localTime. The planner already used calendar wall times.

New regression checks 09:00 and 20:15 on spring/fall transition dates, including correct day/hour/minute. All 14 core tests pass and unsigned iPhone build succeeds. This establishes conversion correctness and compilation; native picker setting/permission/pending queue/delivery checks remain open. Reminder score stays 6/10.

## Native reminder setup acceptance

Device Hub changed frequency from 1 to 3 and saved with switch off: status became Moments are paused. Your design is kept. Enabled and saved; native notification permission prompt appeared, Allow completed and app reported 60 moments planned through 5 Nov 2026. LibraryStore configure awaits UNUserNotificationCenter.add for each request before reporting success; this is queue-submission evidence, not observed OS delivery. Pause changed the switch to off and retained the design.

Selected One special quote with no specific quote, enabled and saved: visible alert rejected it with Add a quote or follow a channel before enabling moments. Prior valid schedule had already been paused; no new schedule created. Reminder setup raised to 7/10; actual background delivery/tap and denial acceptance remain open. Runtime used the prior built app; DST helper change has core/build evidence and still awaits rebuilt UI inspection.
