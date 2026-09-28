# Changelog

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
