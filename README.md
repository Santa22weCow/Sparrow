# Sparrow 🐦

Sparrow is a modern iOS signing and sideloading app built from the Feather codebase, with extra tools for repository management, bulk signing, provisioning-profile checks, embedded components, and app management.

> Sparrow is an independent modified project. It is not an official Feather release.

## Features

- Sign and install IPA files using your own certificate
- Import `.p12` certificates and provisioning profiles
- Add and manage app repositories
- Pin favorite repositories
- Track which source an app came from
- View available app versions from supported repositories
- Bulk sign multiple apps
- Re-sign existing apps
- Provisioning-profile compatibility checks
- Wildcard and explicit App ID detection
- Entitlement compatibility warnings
- Apple Watch component controls
- Optional unique keychain groups
- Embedded extension browser
- Embedded dylib/framework browser
- Library export tools
- No bundled private signing credentials

## Signing

Sparrow does not include any signing certificate, private key, provisioning profile, or certificate password.

Users must provide their own:

- `.p12` certificate
- provisioning profile
- certificate password if required

Never publish private signing files in a public repository.

## Building Sparrow

### Requirements

- macOS
- Xcode
- Your own Apple signing configuration

### Build steps

1. Clone the repository.
2. Open `Feather.xcodeproj` in Xcode.
3. Select the app target.
4. Configure your own signing team.
5. Build and run on your device.

The public version of Sparrow does not require private certificate files.

## Security

The public repository should never contain:

```text
*.p12
*.pfx
*.mobileprovision
Secrets.xcconfig
PrivateSigning/
```

Normal certificate import remains available in the app, but all signing material must be supplied by the user at build or runtime.

## Credits & Upstream Project

Sparrow is a modified version of [Feather](https://github.com/claration/feather).

Feather and its original source code are provided by the Feather developers and contributors. Sparrow contains independent modifications and additional features and is not the official Feather project. Sparrow does not imply endorsement by CLARATION or any Feather contributor.

The project remains licensed under the [GNU General Public License v3.0](LICENSE).

Original Feather license: [github.com/claration/Feather/blob/main/LICENSE](https://github.com/claration/Feather/blob/main/LICENSE)

## Disclaimer

You are responsible for complying with Apple’s terms, applicable laws, and the licenses of software you install or sign.

## License

Sparrow is distributed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
