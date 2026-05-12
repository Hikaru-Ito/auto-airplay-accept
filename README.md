# AirPlay Auto Accept

> A tiny background macOS app that automatically clicks "Accept" on incoming AirPlay connection dialogs.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-11%2B-black.svg)](https://www.apple.com/macos/)
[![Made with AppleScript](https://img.shields.io/badge/Made_with-AppleScript-lightgrey.svg)]()

Every time you AirPlay from an iPhone or iPad to your Mac, macOS asks you to approve the connection. Even from a device you've connected a hundred times before, you still get the same dialog.

Install this app and that click goes away. It runs silently in the background and accepts AirPlay connections for you.

**Landing page:** https://hikaru-ito.github.io/auto-airplay-accept/

## ✨ Features

- **Zero interaction** — automatically clicks "Accept" the moment an AirPlay banner appears
- **Language-independent** — identifies the Accept button by structure/position, not localized label, so it works on any macOS language
- **Fully background** — no Dock icon, no menu bar item, no window
- **Lightweight** — built on AppleScript; negligible CPU/memory footprint
- **Open source** — under 100 lines of AppleScript you can audit before running

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

The AirPlay receiver prompt on modern macOS is **not a regular dialog window** — it's a notification banner rendered by the `NotificationCenter` process, and its button labels are not exposed via the Accessibility API. A naive `click button "Accept"` does not work.

1. `osacompile -s` compiles the AppleScript as a **stay-open applet**
2. The applet's `on idle` handler runs once per second
3. It walks the UI element tree of `NotificationCenter`'s windows and looks for a group containing:
   - a static text whose value is `AIRPLAY` (this is the system badge, identical across all locales)
   - at least 2 buttons (Decline / Accept)
4. Among those buttons, it clicks the one with the **largest Y coordinate** (the one positioned lower on screen) — that's always the Accept button on macOS
5. `LSUIElement = true` in `Info.plist` hides the app from the Dock and menu bar

The entire implementation lives in [`src/main.applescript`](src/main.applescript) — around 90 lines.

## ⚙️ Configuration

You can edit `src/main.applescript` and rebuild to customize:

- `pollInterval` — how often to scan for banners (default: 1 second)
- `airplayBadge` — the system badge string used to identify AirPlay banners (default: `AIRPLAY`)

## 🐛 Troubleshooting

### The app isn't clicking anything

1. **Check that Accessibility permission is granted.**
   System Settings → Privacy & Security → Accessibility → confirm `AirPlay Auto Accept` is in the list and toggled ON. Note: macOS binds this permission to the exact app path and code signature, so if you rebuilt the app or moved it, you may need to remove and re-add it.
2. **Check that the app is running.**
   ```bash
   pgrep -f "AirPlay Auto Accept"
   ```
   No output means the app has quit.
3. **Inspect the banner structure.**
   With the AirPlay banner visible, this dumps the relevant UI tree:
   ```bash
   osascript -e 'tell application "System Events" to tell process "NotificationCenter" to get entire contents of every window' 2>&1 | tr ',' '\n' | grep -iE "AIRPLAY|button"
   ```
   If you don't see `static text "AIRPLAY"`, the banner identifier may differ on your locale/version — update `airplayBadge` in `src/main.applescript` accordingly.

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
