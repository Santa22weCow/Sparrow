# Sparrow enhancement report

## Source favorites / pinning
**Status:** IMPLEMENTED

**What changed:** Sources now persist an `isPinned` flag in Core Data, display pinned repositories first, retain search behavior, and offer Pin/Unpin in each source context menu.

**Files changed:** Core Data model, `Storage+Sources.swift`, `SourcesView.swift`.

**How to test:** Open Sources, long-press a source, select Pin Source, restart Sparrow, and confirm it remains first. Search for it by name.

**Known limitations:** None known.

## Delete signed IPA after successful installation
**Status:** IMPLEMENTED

**Implementation:** Added an opt-in setting. Cleanup runs only after confirmed successful server installation, targets only the generated `.ipa`, and logs failures without affecting installation. Failed or cancelled installs retain the artifact.

**Files changed:** `ServerInstaller.swift`, `InstallPreviewView.swift`, `SigningOptionsView.swift`.

**How to use:** Enable “Delete signed IPA after successful installation” under Signing Options → Post Signing.

**How to test:** Test with the setting off and on; verify failed/cancelled installs retain the signed IPA.

**Known limitations:** The advanced iDevice installation path needs a separate completion callback to perform the same cleanup.

## Bulk signing / resigning
**Status:** IMPLEMENTED (core queue)

**Implementation:** Added a sequential `FR.BatchSigningQueue` that reuses `FR.signPackageFile`, tracks queued/preparing/signing/completed/failed/cancelled states, isolates failures, and supports cancellation. Added Bulk Signing settings UI for selecting imported apps and a certificate.

**Files changed:** `FR.swift`, `BulkSigningView.swift`, `ConfigurationView.swift`.

**How to use:** Settings → Signing Options → Bulk Signing, select apps and a certificate, then start signing.

**How to test:** Pending.

**Known limitations:** The current UI is intentionally compact; retry and detailed summary presentation are still follow-up polish, and re-signing already-signed items is not exposed as a separate command.

## Identifier / provisioning-profile assistance
**Status:** IMPLEMENTED (profile compatibility core)

**Implementation:** Existing provisioning-profile parsing and identifier replacement rules were preserved. Identifier rules now support inline editing and validate bundle-identifier syntax, duplicate keys, and empty values before saving.

**Files changed:** `ConfigurationDictAddView.swift`, `ConfigurationDictView.swift`.

**How to use:** Existing identifier mappings remain available under Signing Options → Identifiers.

**How to test:** Existing signing workflows build successfully.

**Known limitations:** Entitlement-by-entitlement diagnostics and rule enable/disable controls remain follow-up work.

### Phase 2 follow-up implementation

The queue now exposes failed-item retry logic, and identifier rules persist enabled/disabled state without changing the existing options schema. Profile diagnostics now include common keychain, App Group, associated-domain, push, and debug entitlements. A full batch summary/re-sign-all workflow and replacement-policy UI remain incomplete.

## Phase 3

### Apple Watch handling
**Status:** IMPLEMENTED. Added a persisted “Keep Apple Watch Components” option (default enabled). The signing handler now removes Watch content only when explicitly disabled.

### Unique keychain groups
**Status:** IMPLEMENTED (profile-gated). Added an opt-in deterministic TeamID.bundleID group. It is applied only when the selected profile authorizes the value; otherwise existing groups remain unchanged.

### Extension management and library extraction
**Status:** IMPLEMENTED (read-only browser). Added embedded component discovery and embedded dylib/framework browsing. Browsing only enumerates the already-imported app directory and does not rewrite the source IPA.

**Files:** `EmbeddedComponentsView.swift`, `EmbeddedLibrariesView.swift`, `SigningView.swift`.

**Known limitations:** Component toggles are persisted for UI/policy use; the signing engine still signs required embedded bundles as a unit. Current export uses system ShareLink for individual dylibs; framework ZIP packaging and multi-selection export remain limited by the current UI.

## Repo-linked update tracking, version selection, source information
**Status:** IMPLEMENTED (existing, preserved)

**What changed:** Confirmed Sparrow already records `SourceAppProvenance` and `AppSourceMetadata`; version history lets users choose a version and carries provenance through download/import.

**Files:** `Storage+SourceMetadata.swift`, `UpdateManager.swift`, source detail/version views.

**How to test:** Download an app from a source, open its source detail, select Version History, and choose a version.

**Known limitations:** Remaining enhancement phases are listed in `SPARROW_ENHANCEMENT_PLAN.md` and have not yet been implemented.

## Phase 4 — Sparrow updates

**Status:** Implemented.

**Files changed:** `Feather/Views/Settings/SettingsView.swift`.

**Architecture:** `SparrowUpdateManager` reads only the public Sparrow GitHub releases API, ignores prereleases for the stable channel, compares versions numerically, caches the last-check timestamp, and exposes release metadata and IPA assets. `SparrowUpdatesView` is available from Settings.

**How to use:** Settings → Sparrow Updates → Check for Updates. A newer official IPA can be opened from the release asset link for explicit review, signing, and installation through the existing workflow.

**Testing:** Build source validation completed; device/API scenarios remain to be exercised manually.

**Limitations:** Beta channel selection, automatic 12–24 hour scheduling, and an in-app download/sign confirmation flow remain follow-up work.

## Phase 4 — Share/import handoff

**Status:** Existing document handoff preserved and branded metadata retained.

**Architecture:** `Info.plist` registers IPA/TIPA document types. `FeatherApp` accepts file URLs, handles security-scoped provider URLs, and routes them to `FR.handlePackageFile`, which reuses the existing import pipeline. No separate import database or private signing material was added.

**Limitations:** A dedicated Share Extension UI with Import & Sign controls, progress UI, and drag-and-drop remains future work.

## Phase 4 continuation — Share handoff and update workflow

**Status:** Share handoff implementation added; extension target configuration is present in the project file, but full target verification is blocked by Xcode package checkout corruption in local DerivedData.

**Files added:** `Feather/Backend/Import/SparrowShareHandoff.swift`, `SparrowShareExtension/ShareViewController.swift`, `SparrowShareExtension/Info.plist`, `SparrowShareExtension/SparrowShareExtension.entitlements`.

**Architecture:** A Sparrow-specific App Group (`group.com.sparrow.app`) stores transactional pending jobs. The extension copies the provider file into a hidden partial directory, writes metadata, atomically renames the job, then writes a `ready` marker. Sparrow consumes ready jobs at launch through the existing `FR.handlePackageFile` import pipeline. The extension never signs.

**Update workflow:** The existing official-release screen now provides channel-aware cached checks and IPA asset links. Download/sign/install remains explicit and is not performed silently.

**Known limitations:** The local Xcode package graph must be repaired before both-target compilation can be confirmed. The extension UI is intentionally lightweight; app metadata preview and a full in-extension certificate availability check remain follow-up polish.
