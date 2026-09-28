# Sparrow Power Tools Report

## Storage Cleaner

Status: PARTIAL

`SparrowStorageManager` scans only Sparrow-owned Documents, Application Support, and Caches locations off the main thread. Imported apps and certificate storage are protected; explicitly selected removable categories can be removed. Cleanup is confirmed and recorded without personal paths. Fine-grained per-file candidate review and active-job exclusion still need to be added.

## Icon Studio

Status: PARTIAL

File-based PNG icon replacement is performed in a temporary copy, square-cropped, validated through packaging, and imported as a new Sparrow item. Apps whose icons exist only in compiled asset catalogs are reported as unsupported rather than modified unsafely.

## Sign & Install

Status: PARTIAL

The workflow selects an imported app, checks the default preset/certificate/profile and bundle compatibility, then opens Sparrow's existing signing flow. It does not duplicate signing or installation engines. Automatic post-sign installation remains limited by the existing signing result presentation and installer confirmation flow.

## Certificate Vault

Status: PARTIAL

The vault reuses existing certificate records and `CertificatePasswordStore`, which stores remembered passwords in the device-only Keychain. The UI never displays password material and supports removal of the associated Keychain item. LocalAuthentication unlock is available in the vault UI; wiring that lock state into every signing operation remains a follow-up.

## Build verification

The Sparrow Release iOS target built successfully after each tool integration. A full device test of Photos/file picking, biometric prompts, and IPA installation still requires a physical iOS device.
