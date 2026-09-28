# Sparrow UI Simplification Report

## Goal

Make the normal flow feel like: import or download → Library → sign → install, while keeping power-user features available.

## Old navigation

The default tab bar exposed App Store, Sources, Library, and Settings, while Settings also exposed Dashboard, a broad Features group, Toolbox, diagnostics, storage, signing, and installation utilities as peers.

## New navigation

1. Library (default launch screen)
2. Sources
3. Signing
4. Updates
5. Settings

## Changes

- Replaced the default App Store tab with a focused Signing tab. App Store browsing remains available from Sources → More.
- Made Library the default tab and simplified its empty state to “No Apps Yet” with a direct Import IPA action.
- Added primary Sign, Sign & Install, Install, and Export actions to App Details.
- Moved IPA inspection, comparison, cloning, version history, bundle inspection, and executable inspection under App Details → Advanced.
- Renamed the visible Toolbox destination to Advanced Tools and retained its existing destinations.
- Rebuilt Settings into General, Signing, Storage, Advanced, and About groups.
- Grouped source import/export and clipboard utilities behind Sources → More.
- Simplified visible wording such as Version History, Change App Icon, and Certificate Security.

## Preserved functionality

No backend feature was deleted. Signing, installation, source health/loading, App Store browsing, diagnostics, activity history, storage cleanup, IPA inspection/comparison, version history, icon tools, clone tools, certificate vault/security, extension browsing, framework/dylib browsing, drag-and-drop, Files import, Share Extension import, and deep-link handlers remain in the project.

## Build and regression verification

- Main Release target: PASS.
- SparrowShareExtension target: PASS.
- Combined app: PASS.
- `Sparrow.app/PlugIns/SparrowShareExtension.appex`: PRESENT.
- Library import/sign/install path: preserved by existing handlers and new primary actions.
- Sources download path: preserved.
- Advanced inspector/version-history path: preserved under App Details.

## Known limitations

Manual physical-device accessibility and install testing is still required. Existing third-party dependency warnings remain unchanged.
