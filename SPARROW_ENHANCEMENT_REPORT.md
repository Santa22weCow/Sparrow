# Sparrow enhancement report

## UI simplification pass
**Status:** IMPLEMENTED

**Architecture:** The existing signing, source, diagnostics, storage, inspector, comparison, version-history, clone, icon, and certificate-security implementations were preserved. Only their presentation and entry points were reorganized around progressive disclosure.

**Files changed:** `Feather/Views/TabView/TabEnum.swift`, `Feather/Views/TabView/Bars/TabbarView.swift`, `Feather/Views/Library/LibraryView.swift`, `Feather/Views/Library/Info/LibraryInfoView.swift`, `Feather/Views/Sources/SourcesView.swift`, `Feather/Views/Settings/SettingsView.swift`, `Feather/Views/Settings/SparrowToolboxView.swift`, `Feather/Views/Settings/SparrowVersionVaultView.swift`.

**New navigation:** Library (default), Sources, Signing, Updates, Settings.

**Moved behind secondary navigation:** Dashboard, diagnostics, activity, storage management, IPA inspection, comparison, version history, icon customization, cloning, certificate security, archive/install diagnostics, and source management utilities.

**Preserved:** Share Extension import, drag-and-drop, Files import, URL import, source search/pinning, App Store browsing, signing preflight, installation, and all advanced backend services.

**Regression paths:**

- Library → Import IPA → Sign → Install remains available.
- Sources → App Store/Source Apps → Download → Library remains available.
- App Details → Advanced → Inspect IPA/Compare/Version History remains available.
- Settings → Advanced Tools → Storage/Diagnostics remains available.
- Settings → Signing → Certificates/Certificate Security remains available.

**Build verification:** Release build completed successfully with `SparrowShareExtension.appex` embedded in `Sparrow.app`. Existing package warnings remain outside this pass.

**Known limitations:** Physical-device install and VoiceOver/Dynamic Type review still require manual device QA; the five-tab layout is intentionally fixed for a simpler default experience.

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

## Phase 5 foundation

Diagnostics and bounded privacy-safe activity history are implemented. Larger Phase 5 feature groups remain pending and Phase 6 has not started.

## Phase 5 increment

Added a native Sparrow Dashboard, privacy-safe bounded activity history/diagnostics, and persistent signing presets. Existing signing and import engines remain unchanged. Certificate health, cloning, source backup/health, advanced Library filtering, and richer batch controls remain pending.

Phase 5 now also includes persistent signing presets, a native Dashboard summary, and source list export/import that excludes credentials and certificate material.

Phase 5 now includes expiry status pills on certificate cards and a timeout-bounded source health checker built on the existing repository URL model.

Phase 5 final increment adds a confirmation-preserving Quick Sign entry point, broader Library search fields, clipboard source selection, and source/certificate health logic. Full clone editing and advanced batch preset UI remain follow-up limitations.

## Power Tools completion pass

The four existing Power Tools were extended as far as the iOS APIs and current architecture safely allow. See `SPARROW_POWER_TOOLS_REPORT.md` for per-tool status, tests, and explicit limitations.

## Advanced tools continuation

### JIT Enabler
**Status:** SAFETY-GATED UI IMPLEMENTED. Sparrow reports local pairing metadata and routes users to the existing tunnel/pairing workflow. It does not claim JIT success without a supported helper because public iOS APIs cannot grant a JIT entitlement to an installed app.

### Device Identifier Grabber
**Status:** IMPLEMENTED. Device Identifiers shows iOS-provided device name, model, OS version, identifierForVendor, and the presence (without exposing contents) of local pairing metadata. Copy and Copy All are available.

### Controlled File Manager
**Status:** IMPLEMENTED. File Manager is restricted to Sparrow's Unsigned, Signed, Archives, and Certificates directories. It supports search, safe delete, IPA/profile/P12/plist/ZIP classification, plist preview, and system sharing/export.

### App Capability Viewer
**Status:** IMPLEMENTED. App Capabilities reuses SparrowIPAInspector for bundle metadata, embedded components, URL schemes, and detected entitlement categories.

**Files:** `Feather/Views/Settings/SparrowAdvancedToolsViews.swift`, `Feather/Views/Settings/SparrowToolboxView.swift`.

**Known limitations:** Existing DownloadManager and BulkSigningView remain the source of truth for download and sequential signing queues. Full JIT activation requires an external, platform-compatible pairing/JIT helper; Sparrow deliberately never fabricates a success result. Duplicate-import conflict UI and a richer source category browser remain follow-up work.
