# Sparrow

A modern iOS signing and sideloading app based on Feather.

Sparrow is a modified fork of [Feather](https://github.com/claration/feather) with source browsing, local installation, bulk signing, profile diagnostics, Apple Watch controls, extension browsing, and embedded-library tools.

## Signing

Sparrow ships with no signing credentials. Users must import their own `.p12` certificate and provisioning profile through the Certificates settings. Private keys, passwords, and provisioning profiles are never included in this repository.

## Building

Open `Feather.xcodeproj` in Xcode, select the Sparrow/Feather target, configure your own signing team, and build for a connected device. Dependencies are included as Swift packages/submodules used by the project.

## Credits & Upstream Project

Sparrow is a modified version of [Feather](https://github.com/claration/feather). Feather and its original source code are provided by the Feather developers and contributors. Sparrow contains modifications and additional features and is not the official Feather project. The project remains licensed under the [GNU General Public License v3.0](LICENSE).

## Disclaimer

You are responsible for complying with Apple’s terms, applicable laws, and the licenses of software you install or sign.

## License

GNU General Public License version 3. See [LICENSE](LICENSE).
