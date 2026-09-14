# Launcher Launcher

> One launcher to launch them all — because apparently your game launchers needed adult supervision.

Launcher Launcher is a native SwiftUI macOS app that finds game launchers, compatibility wrappers, and related tools, then puts them behind one polished Launch button.

## Features

- Automatically scans `/Applications` and `~/Applications`
- Recognizes Steam, Whisky, CrossOver, Mythic, Heroic, PlayCover, Porting Kit, Prism Launcher, and other launcher-like apps
- Add any `.app` manually with the picker or drag and drop
- Native app icons, search, favorites, remove, rescan, and Show in Finder
- Saves the catalog and favorites in Application Support
- Explains the recursive joke without making the interface itself a joke

## Requirements

- macOS 14 or newer
- Swift 6 toolchain, or Xcode 16 or newer

## Build and run

### From Terminal

```sh
cd LauncherLauncher
swift run
```

The first build can take a moment. A normal macOS app window will open.

To run the checks:

```sh
swift test
```

### In Xcode

1. Open `Package.swift` in Xcode.
2. Select the **LauncherLauncher** scheme and **My Mac** destination.
3. Press Run (`⌘R`).

To build an installable `.app` and ZIP, run `bash scripts/package.sh`. Results appear in `dist/`. The build targets the current machine's architecture and is ad-hoc signed. It is not Apple-notarized; downloaded builds may require approval in System Settings → Privacy & Security.

Tagged releases are tested and packaged on GitHub's macOS runner. The initial release targets Apple Silicon and macOS 14 or newer.

## How discovery works

At launch and whenever **Scan Again** is clicked, the app walks the two standard application folders without descending into app bundles. It matches a maintained list of known gaming tools plus launcher-related names and bundle identifiers. Unknown apps can always be added manually.

The saved catalog lives at:

```text
~/Library/Application Support/LauncherLauncher/launchers.json
```

Removing an automatically found app hides it only until the next scan. Deleting or moving the original app is never performed.

## Privacy

Everything happens locally. Launcher Launcher does not use the network, collect analytics, or modify the apps it discovers.
