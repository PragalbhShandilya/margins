# Margins for iPhone

A native SwiftUI app for iPhone running iOS 17 or later. This is an editable Xcode project, not an installed app or an App Store release.

## Open and run later

1. Download this branch from GitHub (**Code → Download ZIP**).
2. In the `ios` folder, open **Margins.xcodeproj** in Xcode. Open the project rather than Package.swift; the package is the portable testable core only.
3. Choose the **Margins** scheme and an iPhone simulator, then Run. No account or backend is required for the private library and local moments.
4. For your own iPhone later: connect the phone, enable Developer Mode, select it in Xcode, and choose your Apple development team under **Signing & Capabilities**. If the sample bundle identifier is unavailable, replace `com.pragalbh.margins` with your own unique identifier. Then Run.

No development team, signing certificate or private account credential is included. An unsigned `.app` was compiled to verify the iPhone build; it cannot be installed on a physical phone without signing.

## What is included

- Five native tabs: For you, Library, Moments, Channels and People.
- A warm paper and muted-green interface with serif typography and native navigation.
- Add book, film, family and friend quotes, edit, favorite, search, filter, sort, remove and undo.
- Read and follow bundled serious/funny editorial collections. Their quotes can supply reminders.
- Make quote cards using forest/sea/paper gradients or your own photo, and share the image or words using the iPhone share sheet.
- Random **local notifications** with quote images, chosen words and quiet hours. These do not need a backend to work while the app is closed. Permission and actual iPhone notification settings still apply.
- Atomic on-device collection storage, JSON backup export/import, photo backup, and recovery-file export if an existing collection cannot be read.
- Import a version-3 JSON backup exported from the existing Margins website. Author, source, favorites and followed editorial channels are retained. Reminders stay paused after import.
- A native client for the prepared community API: connect an HTTPS server later, create/sign in to accounts, discover/follow readers, read their feed, publish individual quotes, and unpublish your shared quotes. Tokens use the iPhone Keychain.

## Local notification behavior

Save an enabled Moments design and grant permission. The app schedules up to 60 randomized, non-repeating requests inside the selected hours, spread over the coming 20–30 days depending on frequency. Opening Margins replenishes the queue when fewer than 30 requests remain. Reopen regularly; this does not promise an unlimited unattended schedule.

A notification contains the quote, author and an attached card image. Tapping it opens that quote card. The OS controls delivery, Focus modes and image presentation. There is no critical-alarm entitlement. Pause removes pending Margins notifications; deleting the last eligible quote pauses its reminders. Changes to eligible collections request a refreshed schedule.

Your own photo and private quotes stay on the iPhone. Local notification scheduling does not upload them. The community server receives only profile/account information and quotes you explicitly publish. There is no automatic private-library cloud sync.

The default backgrounds are native gradients and subtle symbol illustrations. Personal-photo cards use the image you choose with Apple’s photo picker.

## Verify

```sh
xcodebuild -project Margins.xcodeproj -scheme Margins -sdk iphoneos \
  -destination 'generic/platform=iOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
swift test
```

`Package.swift` contains the Foundation-only core and its tests. The app target compiles the core sources directly, with no external package dependency. A repository workflow builds the iPhone target and runs the core tests on a macOS runner.

## Verification completed

- **Unsigned iPhone build: succeeded** with Xcode 27.0 / iPhoneOS 27 SDK and an iOS 17 minimum target.
- **12 core tests passed**, covering quote validation, search, favorites, selected-quote identity, backup round-trip/merging, invalid imports, followed channel pools, quiet-hour validation, randomized slots, request cap, midnight/DST planning, native photo backups and import from the web app.
- Swift sources were formatted and type-checked with the iPhone SDK.
- App icon, privacy manifest, Info.plist and shared Xcode scheme are included.

## Checks still needed on a simulator or iPhone

Xcode and Device Hub successfully built and launched the app on the iPhone 18 Pro / iOS 27 simulator. The home screen and Library navigation were visually checked. The shared Run scheme launches without debugger attachment because attachment stalled on this host. Photo-picker interactions, share-sheet behavior, Keychain runtime behavior, notification permissions and app-closed delivery have **not** been runtime verified. No iPhone installation was attempted, as requested.

Before release, run these acceptance checks:

1. Add/edit/favorite/search/delete/undo a quote and confirm persistence after relaunch.
2. Export a backup, import it on another installation, and verify no duplicates. Import a web JSON backup and check attribution/favorites.
3. Follow/unfollow a channel and verify the feed and reminder choices.
4. Choose a photo and share a readable card, including a long quote and large text settings.
5. Enable a short quiet-hours window, receive a notification while the app is closed, tap it to open the right card, then pause and verify no further pending alerts.
6. Deny notifications and check the recovery path through iPhone Settings.
7. Once a backend is deployed, test two real accounts, publishing, following/feed, unpublishing, expired sign-in and network failure. Community setup remains deferred.

This project is ready for the requested next step—opening and running it in Xcode. It has not been rated as a fully verified 8/10 release on a real phone.
