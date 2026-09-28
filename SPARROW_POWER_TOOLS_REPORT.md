# Sparrow Power Tools Report

## Storage Cleaner

Status: COMPLETE

`SparrowStorageManager` scans only Sparrow-owned Documents, Application Support, and Caches locations off the main thread. Imported apps and certificate storage are protected; only explicitly selected signed builds, archives, and cache locations can be removed. Cleanup is confirmed and recorded without personal paths.

## Icon Studio

Status: PARTIAL

File-based PNG icon replacement is performed in a temporary copy, square-cropped, validated through packaging, and imported as a new Sparrow item. Apps whose icons exist only in compiled asset catalogs are reported as unsupported rather than modified unsafely.

## Sign & Install

Status: PARTIAL

The workflow selects an imported app, checks the default preset/certificate/profile and bundle compatibility, then opens Sparrow's existing signing flow. It does not duplicate signing or installation engines. Automatic post-sign installation remains limited by the existing signing result presentation and installer confirmation flow.

## Certificate Vault

Status: COMPLETE

The vault reuses existing certificate records and `CertificatePasswordStore`, which stores remembered passwords in the device-only Keychain. The UI never displays password material, supports removal of the associated Keychain item, and can require LocalAuthentication before protected operations.

## Build verification

The Sparrow Release iOS target built successfully after each tool integration. A full device test of Photos/file picking, biometric prompts, and IPA installation still requires a physical iOS device.
