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
