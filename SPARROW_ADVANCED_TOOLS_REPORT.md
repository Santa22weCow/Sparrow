# Sparrow Advanced Tools Report

## Implemented in this pass

- JIT Enabler status screen with pairing detection and safety-gated messaging.
- Device Identifier Grabber using only local iOS-provided identifiers.
- Controlled File Manager for Sparrow-owned storage locations.
- App Capability Viewer backed by the existing IPA Inspector.
- Existing Bulk Signing queue exposed directly from Advanced Tools.

## Architecture

The tools are implemented in `Feather/Views/Settings/SparrowAdvancedToolsViews.swift` and linked from `SparrowToolboxView`. They reuse `HeartbeatManager` pairing metadata, `SparrowIPAInspector`, `FileManager` storage extensions, `ShareLink`, and the existing `FR.BatchSigningQueue`. No parallel signer or fabricated device/JIT identity was introduced.

## Verification

The Release app target was built with signing disabled. Manual device testing is still required for pairing availability, file-provider sharing, and large-file behavior.

## Limitations

JIT activation itself requires an external helper and a supported device/OS combination. The file manager intentionally cannot browse outside Sparrow-controlled directories. Duplicate IPA conflict resolution and richer source categorization remain future work.
