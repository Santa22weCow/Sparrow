# Changelog

## Unreleased — UI simplification

- Library is now the default launch screen.
- Main navigation is limited to Library, Sources, Signing, Updates, and Settings.
- Advanced tools remain available under Settings → Advanced Tools instead of primary navigation.
- App details now emphasize Sign, Sign & Install, Install, and Export, with inspection and power tools under Advanced.
- Source import/export, clipboard actions, and the App Store are grouped behind the Sources More menu.
- Empty Library and technical labels were simplified for first-time users.
- Added Advanced Tools for JIT/pairing status, privacy-safe device identifiers, controlled file browsing, app capability inspection, and bulk signing access.

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
