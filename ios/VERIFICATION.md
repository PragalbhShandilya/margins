# iPhone project verification

16 October 2026

- Xcode 27.0, build 27A266a; iPhoneOS 27 SDK; minimum deployment iOS 17.
- Generic arm64 iPhone build with `CODE_SIGNING_ALLOWED=NO`: **BUILD SUCCEEDED**.
- Portable Foundation core: **12 XCTest tests passed, 0 failures**.
- App icon, Info.plist, privacy manifest, shared scheme and source references validated during the Xcode build.
- No third-party iOS dependencies or embedded account/signing credentials.

## Scope of the evidence

This verifies compilation/linking and the core data/scheduling rules. It does not prove visual quality, notification permission or actual delivery, photo picking/sharing, Keychain integration or community server behavior on a device. Shell-based CoreSimulator access was unavailable, but Xcode and Device Hub successfully built, installed and ran Margins on the iPhone 18 Pro / iOS 27 simulator. Home screen and Library navigation were visually verified. The first debugger attachment stalled; disabling Debug executable in the Run scheme allowed a successful launch. The owner requested project preparation rather than an iPhone installation.

Read README.md for the device acceptance checklist and installation steps to use later.
