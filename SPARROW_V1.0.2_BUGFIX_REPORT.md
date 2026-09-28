# Sparrow 1.0.2 Bug-Fix Report

## Issue #504 — signing settings corruption

Status before: PARTIAL. Root cause: fragile JSON merge/decoding could accept inconsistent values or silently replace saved settings after a decode failure. The manager now decodes the typed model directly, canonicalizes valid settings, preserves invalid bytes as a local recovery backup, and reports a warning instead of logging sensitive data.

Files: `Feather/Backend/Observable/OptionsManager.swift`.

Verification: Release build passed; invalid persistence now falls back deterministically without crashing signing.

## Issue #590 — certificate revocation crash

Status before: APPLIES. Root cause: revocation callbacks could use missing files or mutate a Core Data object from the callback context. Import now rolls back if secure password storage fails, validates readable files, and applies only a positive revocation result on the main context.

Files: `Feather/Backend/Storage/Storage+Certificate.swift`.

Verification: Release build passed; failed/offline checks no longer mark an imported certificate invalid or mutate Core Data off-context.

## Issue #661 — large IPA import failure/progress

Status before: APPLIES. Root cause: file imports used an opaque whole-file copy with no progress and no disk/cancellation checks. Imports now stream 4 MB chunks through a temporary file, report byte progress for download-backed imports, check free space, and reject partial copies.

Files: `Feather/Utilities/Handlers/AppFileHandler.swift`.

Verification: Release build passed. Device testing with multi-GB archives is still required for performance validation.

## Issue #672 — Watch dylib injection

Status before: PARTIAL. Root cause: extension discovery only inspected the root app PlugIns/Extensions folders. Discovery now walks the app bundle for valid `.appex` bundles, including nested Watch targets, while requiring an executable declaration before injection.

Files: `Feather/Utilities/Handlers/TweakHandler.swift`.

Verification: Release build passed. Real Watch-device injection remains dependent on the selected tweak and target architecture.

## Issue #686 — Fully Local certificate update

Status before: PARTIAL. Root cause: certificate files were replaced independently, allowing stale or mixed server identity state after a failed update. New certificate responses are validated and staged before replacing the local server files.

Files: `Feather/Utilities/FR.swift`.

Verification: Release build passed. A live trusted-certificate rotation requires a physical device and the configured certificate provider.
