# AirPlay Auto Accept

> A tiny background macOS app that automatically clicks "Accept" on incoming AirPlay connection dialogs.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-11%2B-black.svg)](https://www.apple.com/macos/)
[![Made with AppleScript](https://img.shields.io/badge/Made_with-AppleScript-lightgrey.svg)]()

Every time you AirPlay from an iPhone or iPad to your Mac, macOS asks you to approve the connection. Even from a device you've connected a hundred times before, you still get the same dialog.

Install this app and that click goes away. It runs silently in the background and accepts AirPlay connections for you.

**Landing page:** https://hikaru-ito.github.io/auto-airplay-accept/

## ✨ Features

- **Zero interaction** — automatically clicks "Accept" the moment an AirPlay dialog appears
- **Multilingual button detection** — recognizes `Accept`, `Allow`, `受け入れる`, `許可`, and more
- **Fully background** — no Dock icon, no menu bar item, no window
- **Lightweight** — built on AppleScript; negligible CPU/memory footprint
- **Open source** — under 50 lines of AppleScript you can audit before running

## 📦 Installation

### Option A — Download the prebuilt binary

1. Grab the latest `AirPlayAutoAccept-x.y.z.dmg` from the [Releases page](https://github.com/Hikaru-Ito/auto-airplay-accept/releases/latest)
2. Open the DMG and drag `AirPlay Auto Accept.app` into your `Applications` folder
3. On first launch, **right-click → Open** (the app is signed with an ad-hoc signature, so double-clicking will be blocked by Gatekeeper)
4. When prompted, grant Accessibility permission:
   - System Settings → Privacy & Security → Accessibility → enable `AirPlay Auto Accept`
5. (Optional) Add the app to System Settings → General → Login Items so it starts at boot

### Option B — Build from source

```bash
git clone https://github.com/Hikaru-Ito/auto-airplay-accept.git
cd auto-airplay-accept
./scripts/build.sh
open "dist/AirPlay Auto Accept.app"
```

The build uses only macOS-bundled tools (`osacompile` and `PlistBuddy`). No additional dependencies required.

## 🛠 How it works

1. `osacompile -s` compiles the AppleScript as a **stay-open applet**
2. The applet's `on idle` handler runs once per second, walking through a list of candidate processes (e.g. `ControlCenter`)
3. For each process, it inspects open windows for a button labeled `Accept`, `Allow`, `受け入れる`, etc. and clicks it if found
4. `LSUIElement = true` in `Info.plist` hides the app from the Dock and menu bar

The entire implementation lives in [`src/main.applescript`](src/main.applescript) — around 40 lines.

## ⚙️ Configuration

You can edit `src/main.applescript` and rebuild to customize:

- `pollInterval` — how often to scan for dialogs (default: 1 second)
- `targetButtons` — list of button labels to look for
- `candidateProcesses` — list of processes that may host AirPlay dialogs

## 🐛 Troubleshooting

### The app isn't clicking anything

1. **Check that Accessibility permission is granted.**
   System Settings → Privacy & Security → Accessibility → confirm `AirPlay Auto Accept` is in the list and toggled ON.
2. **Check that the app is running.**
   ```bash
   pgrep -f "AirPlay Auto Accept"
   ```
   No output means the app has quit.
3. **Find out which process is hosting the dialog.**
   While the dialog is visible, run:
   ```bash
   osascript -e 'tell application "System Events" to get name of every process whose visible is true'
   ```
   Add any new process name to `candidateProcesses` in `src/main.applescript` and rebuild.

### "Apple cannot verify..." error on launch

The app is ad-hoc signed, not signed with an Apple Developer ID, so Gatekeeper shows a warning.

- On first launch, use **right-click → Open** instead of double-clicking.
- If that still fails:
  ```bash
  xattr -d com.apple.quarantine "/Applications/AirPlay Auto Accept.app"
  ```

### Uninstall

1. Delete `/Applications/AirPlay Auto Accept.app`
2. Remove it from System Settings → General → Login Items (if you added it)
3. Remove the entry from System Settings → Privacy & Security → Accessibility

## 🧪 Development

### Build the app

```bash
./scripts/build.sh
```

Output: `dist/AirPlay Auto Accept.app`

### Package as DMG

```bash
./scripts/package-dmg.sh
```

Output: `dist/AirPlayAutoAccept-x.y.z.dmg`

### Specify a version

```bash
VERSION=1.1.0 ./scripts/build.sh
VERSION=1.1.0 ./scripts/package-dmg.sh
```

### Cutting a release

Tag and push — GitHub Actions builds the DMG and attaches it to a new GitHub Release automatically:

```bash
git tag v1.1.0
git push origin v1.1.0
```

## 📁 Project structure

```
.
├── src/
│   └── main.applescript        # The applet (AppleScript source)
├── scripts/
│   ├── build.sh                # Build the .app
│   └── package-dmg.sh          # Package a distributable DMG
├── website/
│   └── index.html              # Landing page (multilingual)
├── .github/workflows/
│   ├── release.yml             # Build & upload DMG on tag push
│   └── pages.yml               # Deploy landing page to GitHub Pages
├── dist/                       # Build artifacts (gitignored)
├── LICENSE
└── README.md
```

## 🤝 Contributing

Issues and pull requests are welcome. Ideas worth contributing:

- Adding new localized button labels
- Supporting other macOS approval dialogs (Bluetooth, USB, etc.)
- Designing an app icon
- Adding translations to the landing page

## 📄 License

[MIT License](LICENSE) © 2026 Hikaru Ito

## 🙏 Who this is for

- People who screen-share via AirPlay in every meeting
- Anyone using their Mac as a casual Apple TV substitute
- Engineers who can't help thinking "every small click adds up"
