# Sparrow Power Tools Plan

The power-tools roadmap covers safe, reusable storage management, icon customization, streamlined signing/install, and protected certificate handling. Each tool must reuse Sparrow's existing import, signing, installer, and certificate systems.

## Status

- Storage Cleaner: implemented with an asynchronous Sparrow-owned storage scan and review-before-delete flow.
- Icon Studio: implemented for file-based PNG icons; compiled asset catalogs are reported as unsupported.
- Sign & Install: implemented as a preflight and confirmation entry point into the existing signer. Installation remains governed by the existing installer confirmation flow.
- Certificate Vault: implemented over the existing certificate store and Keychain password store, with optional device authentication.
