# Keymap Companion for Windows

Keymap Companion is a native WinUI 3 desktop app written in Swift 6.3.3. It
discovers the keyboard through QMK Raw HID and provides the same live keymap,
layer, encoder, lighting, tray, reconnect, and delayed layer-HUD features as the
macOS companion.

The Windows presentation is intentionally platform-native and is not shared
with the SwiftUI app. The `@Observable` source of truth, protocol handling,
state reduction, firmware keymap decoding, legends, and keyboard geometry live in the local
[`Shared`](../../Shared) Swift package. WinUI's canvas consumes that shared
rendering model, while macOS continues to draw it with SwiftUI `Canvas`.
The model accesses a shared `KeyboardHardwareClient` through Point-Free's
`@Dependency`; the Windows target injects its SetupAPI/Raw HID adapter at launch.

## Requirements

- Windows 10 version 1809 or newer; Windows 11 is recommended
- Swift 6.3.3 for Windows
- Visual Studio C++ x64 build tools and a Windows SDK
- Microsoft Windows App Runtime 1.7 installed on the computer that runs the app

The build script selects Swift 6.3.3 explicitly, even if a shell inherited an
older `PATH`.

## Build

From PowerShell:

```powershell
.\Windows\KeymapCompanion\build.ps1
.\Windows\KeymapCompanion\build.ps1 -Configuration release
```

The first build runs `bootstrap.ps1`. It downloads pinned Swift/WinRT
projections and the matching x64 Windows App SDK bootstrap library into the
ignored `Windows/KeymapCompanion/Dependencies` directory. SwiftPM also resolves
the pinned Point-Free dependency graph into its normal build cache. Nothing is
installed system-wide. Later builds reuse those files.

Build products are written to:

```text
Windows\KeymapCompanion\.build\x86_64-unknown-windows-msvc\debug
Windows\KeymapCompanion\.build\x86_64-unknown-windows-msvc\release
```

Launch `KeymapCompanion.exe` from the selected directory. The required Swift
6.3.3 runtime DLLs are staged beside the executable automatically. Release
builds use the Windows GUI subsystem, and both configurations embed a
per-monitor-v2 DPI manifest for sharp rendering at non-100% display scaling.

## Controls and behavior

- Closing the main window keeps the app available in the notification area.
- The tray menu can reopen the window, reconnect Raw HID, or exit the app.
- The layer HUD appears after a layer has remained active for three seconds and
  stays out of the way while the main window is active.
- Lighting changes are coalesced before being written to firmware. Incoming
  acknowledgements update existing controls without rebuilding the window.

The keyboard firmware must expose the companion Raw HID protocol and a current
firmware keymap fingerprint. See the [macOS companion documentation](../../macOS/KeymapCompanion/README.md)
for the firmware and protocol workflow shared by both apps.
