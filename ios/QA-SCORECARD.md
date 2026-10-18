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
| Card design / personal photos | 8 | Flower/waterfall photo previews and aspect-ratio repair verified. Saved PNG opened with full 1,426-character quote, both boundary markers and footer in Files Quick Look. |
| Image/text sharing | 8 | Regular and long photo-card PNG exports inspected in Files; regular Info confirms 1080 × 1350. Updated text file visibly contains complete quote, author and book context. |
| Random moments / quiet hours | 7 | Frequency 3 saved while paused; native permission Allow then enabled Save reported 60 scheduled requests through 5 November. Pause disabled the switch and retained design. Missing single-quote selection rejected. 14 core tests cover quiet hours and DST conversion; app-closed delivery/denial and updated picker acceptance pending. |
| App-closed notifications / tap routing | 7 | Actual random notification delivered to simulator Notification Center while Margins was off-screen. Wilde text/author matched a saved quote; pending count fell 60 to 59 on return. Pause restored off state. Tap routing and real physical-device acceptance remain pending. |
| Backup / merge / web migration | 8 | Native Files export/import, duplicate merge, missing-quote restore and photo replacement roundtrip pass. Failed collection-write regression preserves prior data; web migration core tests pass. |
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

## Actual background notification delivery

Configured three daily moments with My library, Forest and a valid 06:19–20:23 local window at approximately 20:20. Scheduling completed with 60 requests. Sent Margins to background via simulator Home and verified Home Screen. After cutoff, Notification Center showed a Margins alert “A moment from Margins” with Wilde’s saved quote and author, timestamp approximately 20:22 (within the chosen window). No banner was observed, so only Notification Center arrival is claimed.

Tapping/advertised View action did not visibly open the app during native automation; routing remains unverified, not classified as an app defect yet. Reopened Margins through Spotlight; app reported 59 pending moments, consistent with one delivered request. Paused reminders again and verified switch off/status paused. Background notifications/routing score raised from 5 to 7. Physical iPhone delivery, expanded image, tap routing and denial recovery still required for full acceptance. Native picker AX setValue did not alter selection; direct wheel row clicks worked, and final values were verified before saving.

## Backup export presentation repair

Native Export collection previously opened a blank sheet on its first presentation. Replaced separate optional URL and Boolean presentation state with one identifiable URL payload, used for normal and recovery exports. Unsigned iPhone build succeeded. Rebuilt app in Xcode and verified the native share sheet showed Margins-collection, JSON, 862 bytes, Copy and Save to Files. Save to Files opened the local destination picker. End-to-end save/reimport is still pending, so backup stays 7/10. Simulator was stopped when the next session resumed; no claim of completed file save.

## Files export follow-up, 18 October

Restarted iPhone 18 Pro in Device Hub and reopened Margins. Export again displayed a populated 862-byte JSON share sheet. Save to Files → On My iPhone → Save returned to Settings. Import and merge backup opened Recents and visibly listed Margins-collection.json, 862 bytes, with the current timestamp: the file save is verified. Selecting it returned to Settings, but no success/error confirmation was visible in the inspected state. Import outcome and collection contents require follow-up; rating remains 7.

## Import confirmation and duplicate merge, 18 October

Found import success status placed below the visible Settings sections. Replaced that status row with a native confirmation alert for successful import/profile saves. Import confirmation explicitly says Moments are paused. Unsigned iPhone build succeeded; Xcode rebuilt and ran on iPhone 18 Pro. Selected the saved 862-byte JSON in Files Recents. Native alert visibly reported “0 quotes imported. Your existing words were kept. Moments are paused.” Dismissed it and opened Library: exactly three quotes remained, with Wilde, movie QA, and life QA text/attribution intact. This verifies reimport duplicate suppression and preservation, not restoration of a missing quote or photo. Backup remains 7 pending those broader acceptance checks.

## Missing-quote restoration acceptance, 18 October

Removed only the disposable movie QA quote using the confirmation flow; Library visibly dropped from three entries to two while preserving Wilde and the attributed life quote. Imported the previously saved JSON from Files without using Undo. Native alert reported one imported quote. Library returned to exactly three entries and displayed the original movie text/category alongside the unchanged book/life text and attribution. Moments showed switch off, My library/Forest/3 per day, prior 06:19–20:23 window, and paused status. This verifies real missing-quote restoration, merge preservation and paused settings. Found singular grammar “1 quotes” in the alert and corrected it to “1 quote”; unsigned iPhone build succeeded. Photo roundtrip and failed-write data safety acceptance remain open, so backup stays 7/10.

## Photo import failed-save safety repair, 18 October

Confirmed source defect: import saved/replaced photo.jpg before collection.json, so a later collection write failure could leave a new photo paired with old quote/settings data. Imports now prepare the image without mutation, write a uniquely named photo, then atomically save the collection referencing it. On write failure, the staged photo is removed; the previous collection and photo remain untouched. Legacy collections continue using photo.jpg when no optional photo reference exists. Photo references are validated as local filenames. Existing old photo files are retained after successful replacement; disk reclamation is not implemented in this change.

Regression injects collection-write failure after photo staging and verifies original JSON bytes, original photo bytes and absence of staged files. Success path reloads the JSON, follows its new photo reference, checks the restored quote/new photo and verifies the old photo was not overwritten. All 15 portable tests pass; unsigned iPhone build succeeds. Native photo-picker/export/restore visual acceptance remains pending. Backup rating stays 7 until that end-to-end path passes.

## Native personal-photo selection acceptance, 18 October

Xcode rebuilt and launched the latest import-safety change on iPhone 18 Pro. Moments → Card background → My photo revealed Choose your own photo; native Photos picker showed six simulator sample images. Selected the flower sample. Preview visibly rendered that image with a dark overlay, complete Wilde quote, author and card footer. Save my moments with switch off reported Moments are paused. Your design is kept. No notification schedule was enabled. Personal-photo/card design rises from 6 to 7; long-text layouts and image export remain unverified. Photo backup roundtrip remains the next backup acceptance gate.

## Photo backup roundtrip completed, 18 October

Exported saved flower design through the native share sheet (JSON 4.3 MB), named Margins-flowers in Files, and saved without replacing the earlier text-only backup. Selected the waterfall sample instead; preview visibly changed to waterfall. Opened Import and merge backup, confirmed Recents listed Margins-flowers.json at 4.3 MB and the old 862-byte collection separately, then chose the flower backup. Alert reported zero new quotes, existing words kept and moments paused. Dismissed Settings: preview visibly returned to flowers with Wilde quote/author and footer intact. Together with prior missing-quote restore, duplicate merge, migration tests and failed-save protection, backup reaches 8/10.

Found a separate card layout defect during this check: the waterfall preview shifted the overlay text right and clipped the category footer, unlike the flower image. Image aspect ratio appears to influence the ZStack layout. Card design stays 7 pending correction and rebuilt retest with both aspect ratios.

## Photo aspect-ratio clipping repair, 18 October

Moved decorative image/gradient layers into a GeometryReader background behind the content-sized card. The photo now fills an explicit card-sized frame and clips within it, so its intrinsic aspect ratio cannot widen the content stack. Unsigned iPhone build succeeded. Rebuilt and ran in Xcode; Device Hub showed flower preview with aligned left margin, complete quote/author and visible Books footer. Selected the same waterfall sample that previously shifted text and clipped Books: rebuilt preview now retained the same left margin and displayed the complete quote, author, margins logo and Books footer. Forest Home hero also visually retained its layout. Card design stays 7 pending long-text and image-export acceptance. The simulator currently uses the waterfall photo, reminders remain off.

## Image export end-to-end acceptance, 18 October

Library → Wilde Quote card used My photo/waterfall. Share image opened the native activity sheet. Save to Files → On My iPhone → Save completed. Opened the simulator Files app: Recents listed PNG image, 2.7 MB. Opened it in the image preview: complete quote, Oscar Wilde, waterfall, margins and Books were visible without clipping. Info confirmed PNG image.png, 1080 × 1350 pixels, normal orientation and sRGB. This is saved-file/rendered-output evidence, not just a thumbnail or compile result. No recipient was messaged. Sharing rises from 5 to 7 pending Share words and long-quote export acceptance. The current simulator foreground is Files image Info.

## Text-sharing export follow-up, 18 October

Reopened Margins from the simulator Home Screen and selected Share words on Wilde’s photo card. Native text share sheet preview began with the expected quote. Save to Files opened the text destination picker; Save returned to the card. Full saved-text contents have not yet been inspected. On the next Home action, Device Hub reported that the Mac was locked and automatic unlock failed. No long-quote test was performed in this session. Sharing stays 7; resume by inspecting the saved text in Files and then creating a disposable long-quote fixture.

## Shared-word attribution improvement, 18 October

Revalidated Device Hub: Mac remains locked and automatic unlock failed. Independent source review found Share words omitted quote.source, losing book/film/family context. Added Quote.shareText and routed ShareLink through it: complete quote plus available author/source, no fabricated Unknown attribution when both are absent. Regression covers full attribution, author-only, source-only, absent attribution and an untruncated long Unicode/multiline quote. All 16 portable tests pass and unsigned iPhone build succeeds. Native updated-share payload and long-card rendering remain pending; sharing stays 7.

## Image-render failure handling, 18 October

Source review found CardRenderer silently returned UIImage() when ImageRenderer failed. Replaced the empty-image fallback with a thrown user-readable error and a positive-dimension guard. CardSheet renders before presenting and carries the successful image in an identifiable payload; failure displays a local alert instead of an empty share. Reminder request construction propagates the error before pending requests are removed. Unsigned iPhone build succeeds. No actual render failure was reproduced; this is failure-path source hardening with build evidence, not runtime failure acceptance. Sharing stays 7 and current image/text/long-quote visual acceptance remains pending while Mac access is locked.

## Long-quote export sizing preparation, 18 October

Reviewed fixed 540 × 675-point export frame against the accepted 2,000-character limit and arbitrary line breaks. Changed renderer to a 540-point fixed width with natural vertical sizing and 675-point minimum height inside QuoteCard. Short exports retain the standard minimum; longer content can expand rather than being constrained to a fixed export height. Unsigned iPhone build succeeded. Updated rendered-file acceptance is still required; no long-export success is claimed.

Device Hub became available again. Created a disposable native book quote with QA LONG START, 25 repetitions of “Every word should remain visible when a card is shared. ” and QA LONG END (1,426 characters including markers/newlines). The input call timed out, but subsequent AX inspection verified the complete input including end marker; Keep saved and Library count became four. Optional attribution was omitted. Fixture remains for rebuilt export inspection. Current simulator app predates this sizing change and the latest share/error improvements; run current Xcode source before acceptance.

## Rebuilt long-card export acceptance, 18 October

Ran latest Xcode source on iPhone 18 Pro, retaining the long fixture after app replacement. Confirmed actual generated fixture length is 1,426 characters (corrected earlier scorecard count). Opened its photo card and Share image; native sheet received a rendered payload. Saved as Margins-long; Files Recents listed PNG, 2.8 MB. Regular image preview remained white, then returned to Files and used the advertised Quick Look action. Quick Look displayed the complete card with QA LONG START, body text, QA LONG END, Unknown attribution, margins and Books footer within image boundaries. This confirms this long fixture exports without clipping, not every possible 2,000-character/newline pattern. Card design/photos reaches 8 based on tested regular/long photo cards, photo selection/persistence and aspect-ratio repair. Sharing stays 7 pending updated Share words file-content verification. Simulator foreground is Files Quick Look for Margins-long.

## Updated text-sharing acceptance completed, 18 October

On the rebuilt app opened Wilde’s card → Share words → Save to Files. Named export Margins-attribution to retain the earlier comparison file. Save returned to card. Opened Files, dismissed the previous long-image Quick Look and located Margins-attribution.txt, 89 bytes. Advertised Quick Look displayed the full expected text: quote, Oscar Wilde, and Lady Windermere’s Fan. No message was sent to a recipient. Combined with inspected regular/long PNG exports and tested optional/Unicode text formatting, image/text sharing reaches 8/10. Simulator foreground is Files Quick Look for Margins-attribution.
