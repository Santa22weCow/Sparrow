# Sparrow enhancement plan

| Feature | Area | Files | Status | Notes | Tests |
|---|---|---|---|---|---|
| Source favorites / pins | Sources | Storage, Sources views | IN PROGRESS | Persistent Core Data pin state | Build + UI ordering |
| Repo updates / version selection | Sources | Existing provenance/update views | IMPLEMENTED (existing) | Preserve and document | Build |
| App source information | Library | Existing source metadata | IMPLEMENTED (existing) | Preserve and document | Build |
| Delete signed IPA after install | Installer | Pending | PLANNED | Must only remove signed artifact after success | Pending |
| Bulk signing | Signing | Pending | PLANNED | Sequential queue to protect memory | Pending |
| Extension/dylib/Watch/keychain | Signing | Pending | PLANNED | One signing-pipeline phase | Pending |
| Share sheet / updater | Integration | Pending | PLANNED | Requires target and configured feed | Pending |
| App data / tvOS | Platform | Pending | RESEARCH REQUIRED | Must respect platform sandboxing | Pending |
| Phase 2: delete signed IPA after install | Installer | ServerInstaller, InstallPreviewView, SigningOptionsView | IMPLEMENTED | Opt-in, signed artifact only, confirmed success only | Build passed |
| Phase 2: bulk signing | Signing | FR.swift, BulkSigningView, ConfigurationView | IMPLEMENTED (core queue) | Sequential queue reuses existing signer; cancellation and per-item states | Build passed |
| Phase 2: identifier/profile assistance | Signing | CertificateModel, SigningView, identifier views | IMPLEMENTED (core compatibility) | Wildcard/explicit matching, team validation, suggestions, rule editing | Build passed |
| Phase 3: Watch component policy | Signing | OptionsManager, SigningOptionsView, SigningHandler | IMPLEMENTED | Keep by default or remove safely when disabled | Build passed |
| Phase 3: Unique keychain groups | Signing | OptionsManager, SigningHandler | IMPLEMENTED | Optional deterministic group, only when profile permits | Build passed |
| Phase 3: Extension/library management | Signing | EmbeddedComponentsView, EmbeddedLibrariesView, SigningView | IMPLEMENTED (read-only browser) | Component discovery, persisted toggles, non-mutating embedded library scan | Build passed |
| Phase 4: Sparrow updates | Integration | SettingsView | IMPLEMENTED | Official GitHub release lookup, stable filtering, semantic version comparison | Build pending disk cleanup |
| Phase 4: Share/import handoff | Integration | FeatherApp, AppFileHandler, Info.plist | EXISTING/PRESERVED | IPA document handoff uses the shared import pipeline and security-scoped URLs | Manual device test |

## Power Tools completion pass

Storage Cleaner now supports per-item review and active-job protection. Icon Studio classifies file-based versus compiled icon storage. Sign & Install hands successful signing into the existing installer. Certificate Vault authenticates before SigningView retrieves protected signing material. Remaining limitations are documented in `SPARROW_POWER_TOOLS_REPORT.md`.
