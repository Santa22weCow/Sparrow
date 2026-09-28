# Sparrow 1.0.2

Bug-fix release focused on signing, importing, Watch components, certificates, and installation reliability.

Fixed:

- Safer signing-settings persistence and recovery from invalid saved values.
- Certificate revocation handling that no longer mutates Core Data unsafely or undoes successful imports.
- Streamed large IPA imports with progress, cancellation checks, and low-storage protection.
- Nested Watch app and Watch extension dylib discovery.
- Validated, staged Fully Local installation-certificate replacement.

No signing certificates or private credentials are bundled with Sparrow.

Artifact: `Sparrow-v1.0.2.ipa`

SHA-256: `845a77130ee0103ad1f05461a4fb2fc7753318c658befcd624bc351050d78bf3`
