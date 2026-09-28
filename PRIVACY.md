# Sparrow privacy notes

Sparrow stores imported applications and signing files in its app container. Certificate passwords are not written to activity history, diagnostics, backups, or presets. When a password is remembered, Sparrow uses the existing device-only Keychain store; otherwise the signing flow asks again. Certificate Vault can require Face ID, Touch ID, or device authentication before protected operations. Icon customization uses a temporary working copy and does not modify the original imported app.
