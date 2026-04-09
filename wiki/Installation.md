# Installation

## From DMG (Recommended)

1. Download `DotCalendar.dmg` from the [Releases](https://github.com/wibawasuyadnya/DotCalendar/releases) page
2. Open the DMG file
3. Drag **DotCalendar** to the **Applications** folder
4. Launch DotCalendar from Applications or Spotlight

> **Note:** On first launch, macOS may show a security prompt. Go to **System Settings > Privacy & Security** and click "Open Anyway".

## Build from Source

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools
- Apple Silicon Mac (arm64)

### Steps

```bash
git clone https://github.com/wibawasuyadnya/DotCalendar.git
cd DotCalendar
chmod +x build.sh
./build.sh
```

### Output

The build script produces:

| Output | Location |
|--------|----------|
| App bundle | `build/DotCalendar.app` |
| DMG installer | `build/DotCalendar.dmg` |

### Manual Install

```bash
cp -r build/DotCalendar.app /Applications/
```

## What the Build Script Does

1. Compiles all Swift source files with `-O` optimization
2. Creates the `.app` bundle structure
3. Copies `Info.plist`, `AppIcon.icns`, and icon assets into Resources
4. Compiles the asset catalog using `actool`
5. Ad-hoc code signs the app
6. Creates a DMG with an Applications shortcut
