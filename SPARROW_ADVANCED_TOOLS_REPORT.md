# Sparrow Advanced Tools Report

## Implemented in this pass

- JIT Enabler status screen with pairing detection and safety-gated messaging.
- Device Identifier Grabber using only local iOS-provided identifiers.
- Controlled File Manager for Sparrow-owned storage locations.
- App Capability Viewer backed by the existing IPA Inspector.
- Existing Bulk Signing queue exposed directly from Advanced Tools.
- Library selection now opens the existing queue with selected imported apps, selected-count controls, preflight status, retry, cancellation, and summary.
- Signed app export now archives the app bundle to a validated IPA and uses the system share sheet.
- Active downloads are visible from Advanced Tools → Download Queue.

## Architecture

The tools are implemented in `Feather/Views/Settings/SparrowAdvancedToolsViews.swift` and linked from `SparrowToolboxView`. They reuse `HeartbeatManager` pairing metadata, `SparrowIPAInspector`, `FileManager` storage extensions, `ShareLink`, and the existing `FR.BatchSigningQueue`. No parallel signer or fabricated device/JIT identity was introduced.

## Verification

The Release app target was built with signing disabled. Manual device testing is still required for pairing availability, file-provider sharing, and large-file behavior.

## Limitations

JIT activation itself requires an external helper and a supported device/OS combination. The file manager intentionally cannot browse outside Sparrow-controlled directories. Full duplicate IPA choice dialogs, source category grouping, persistent paused-download records, and interactive bulk install confirmations remain future work.
