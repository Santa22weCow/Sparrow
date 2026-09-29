# Changelog

## Sparrow 1.0.9

- Redesigned App Store with category chips, featured cards, and must-have app rows.
- Detects non-English descriptions and uses the repository's English localized description when provided.

## Sparrow 1.0.8

- Simplified the primary navigation to exactly four tabs: App Store, Sources, Settings, and Library.
- Signing and Updates remain available from Settings and Advanced Tools.

## Sparrow 1.0.7

- Fixed relaunch-time Sources freezes caused by synchronous repository-cache decoding on the main thread.
- Added cancellable background cache restoration before source refresh.

## Sparrow 1.0.6

- Fixed Sources tab freezes by keeping the stable five-tab navigation on all iOS versions.
- Prevented repository loading from capturing Core Data objects across asynchronous tasks.
- Added network timeouts and safer source refresh behavior.

## Sparrow 1.0.5

- Added a signing-service compatibility build that packages only the main Sparrow app.
- The optional Share Extension is not embedded, avoiding provisioning failures when ESign has no matching extension App ID.

## Sparrow 1.0.4

- Fixed release packaging so the Sparrow Share Extension is signed inside the IPA.
- Removed the release-only debug entitlement (`get-task-allow`).

## Sparrow 1.0.3

- Added Library multi-selection access to the existing sequential bulk-signing queue.
- Added validated signed IPA export through the system share sheet.
- Added Advanced Tools download queue access and stronger source response validation.

## Unreleased — UI simplification

- Library is now the default launch screen.
- Main navigation is limited to Library, Sources, Signing, Updates, and Settings.
- Advanced tools remain available under Settings → Advanced Tools instead of primary navigation.
- App details now emphasize Sign, Sign & Install, Install, and Export, with inspection and power tools under Advanced.
- Source import/export, clipboard actions, and the App Store are grouped behind the Sources More menu.
- Empty Library and technical labels were simplified for first-time users.
- Added Advanced Tools for JIT/pairing status, privacy-safe device identifiers, controlled file browsing, app capability inspection, and bulk signing access.
- Added Library multi-selection entry into the existing sequential bulk-signing queue with preflight counts and retry/summary controls.
- Added validated signed-IPA archive export through the system share sheet.
- Added a secondary Download Queue screen for active source/manual downloads.

## Sparrow 1.0.2

### Bug Fixes

- Hardened signing-settings persistence and safe recovery from invalid saved values.
- Made certificate revocation checks validate inputs and update Core Data safely without undoing a successful import.
- Added streamed large-IPA copying with progress, cancellation checks, and low-storage protection.
- Extended dylib injection discovery to valid nested Watch app and Watch extension bundles.
- Made Fully Local installation-certificate replacement staged and validated before activation.

## Unreleased

- Added Sparrow Storage Cleaner.
- Added Sparrow Icon Studio for file-based PNG icons.
- Added Sparrow Sign & Install preflight workflow.
- Added Sparrow Certificate Vault with Keychain-backed password protection and optional device authentication.
