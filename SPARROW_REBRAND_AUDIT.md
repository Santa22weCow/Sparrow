# Sparrow branding audit

## Scope

This audit records the remaining upstream names after the Sparrow product branding migration.

| Original reference | Location | Action | Reason |
|---|---|---|---|
| Feather product name and bundle identifier | `Feather.xcconfig`, Xcode build settings, `Info.plist` | RENAME | Installed product now displays and builds as Sparrow. |
| Feather/feather URL scheme | `Info.plist`, `FeatherApp.swift` | KEEP FOR COMPATIBILITY | Sparrow emits `sparrow://`; the legacy scheme remains accepted for existing links. |
| Feather storage keys and file prefixes | Swift sources | KEEP FOR COMPATIBILITY | Preserves existing sources, certificates, library data, and preferences. |
| Feather source headers and third-party notices | Swift sources and package licenses | KEEP FOR LEGAL CREDIT | Required upstream attribution and license history. |
| `claration`, `khcrysalis`, and upstream URLs | README, licenses, compatibility links | KEEP FOR LEGAL CREDIT / UPSTREAM CREDIT | Identifies the original Feather project and contributors. |
| Old internal source and target paths | `Feather/`, `Feather.xcodeproj` | REVIEW MANUALLY | Renaming filesystem paths would risk package references and existing build tooling; visible product metadata is Sparrow. |

## Current product identity

- Display name: Sparrow
- Bundle identifier: `com.sparrow.app`
- Product name: Sparrow
- New deep-link scheme: `sparrow://`
- Legacy `feather://` links remain supported for migration.
- Update and repository links use the Sparrow GitHub repository where they are Sparrow-owned.

Remaining matches from a final search must be one of: legal/upstream attribution, compatibility storage keys, legacy file prefixes, or harmless source comments/paths.
