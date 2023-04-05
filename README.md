# Get YubiKey 2fa codes now!

Quickly grab OATH TOTP two-factor codes on a YubiKey from your macOS status bar.

## Ethos

I make apps that I use regularly and I like high-quality apps.
You can get this for free by downloading the release from GitHub,
or you can support development by buying the app on the [App Store](https://r0b.url.lol/yoath)
and you get automatic updates.

## Install

Get Yoath on the Mac App Store to support its development and make sure you've always got the latest version:

[![Download on the Mac App Store](Assets/mac-app-store.svg)](https://r0b.url.lol/yoath)

## Manual install

1. Find the [latest release](https://github.com/robb-j/MiniYubiOath/releases) on GitHub
2. Download and double click to unzip the app
3. Drag it into your Applications folder
4. Double click it to launch

## Auto start

1. Open **System Settings**
2. Navigate to **General → Login Items → Open at Login**
3. Press `+` then choose _Yoath_ from the list

---

<details>
<summary>Dev notes</summary>

## Release

1. Ensure git is clean
2. Make sure [CHANGELOG.md](/CHANGELOG.md) is up to date
3. Update any documentation if needed
4. Bump the version and build in the xcode project
5. Commit those changes as `X.Y.Z`
6. Tag the commit as `vX.Y.Z`
7. **Product → Archive** then **Distribute app → Developer ID → Upload → ...**
8. Push the commit and tag to GitHub
9. Wait for the app to be notarised
10. Create a release from the tag, attach the notarised app and write the release notes

</details>