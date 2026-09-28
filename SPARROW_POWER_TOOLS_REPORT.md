# Sparrow Power Tools Report

## Storage Cleaner

Status: PARTIAL

`SparrowStorageManager` scans only Sparrow-owned Documents, Application Support, and Caches locations off the main thread. The review screen exposes individual removable candidates, sizes, dates, categories, and protected status. Deletion re-checks the active-job registry immediately before each item. Existing imported apps and certificate storage remain protected. Full integration with every importer/update/share job is still a platform/infrastructure limitation.

## Icon Studio

Status: PARTIAL

File-based PNG icon replacement is performed in a temporary copy, square-cropped, and imported as a new Sparrow item. CFBundleIconFiles references are honored. Apps whose icons exist only in compiled asset catalogs are reported as limited rather than modified unsafely.

## Sign & Install

Status: PARTIAL

The workflow selects an imported app, checks the default preset/certificate/profile and bundle compatibility, then opens Sparrow's existing signing flow. On success it hands the newly-created signed record to the existing installer presentation without a manual Library round trip. It does not duplicate signing or installation engines. Retry/export controls for a failed installer attempt remain limited by the existing installer UI.

## Certificate Vault

Status: PARTIAL

The vault reuses existing certificate records and `CertificatePasswordStore`, which stores remembered passwords in the device-only Keychain. The UI never displays password material and supports removal of the associated Keychain item. LocalAuthentication is now enforced before the existing SigningView retrieves protected signing material, with a one-minute in-memory session and explicit lock. Batch-signing and other non-SigningView entry points still require follow-up authorization wiring.

## Build verification

The Sparrow Release iOS target built successfully after each tool integration. A full device test of Photos/file picking, biometric prompts, and IPA installation still requires a physical iOS device.
