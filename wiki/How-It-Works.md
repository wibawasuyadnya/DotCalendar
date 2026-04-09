# How It Works

## Overview

DotCalendar generates a wallpaper image every day that visualizes your year progress as a dot grid. It uses Apple's appearance-aware HEIC format to support automatic light/dark mode switching.

## Step-by-Step Process

### 1. Date Calculation

- Uses `Asia/Singapore` timezone to determine the current day of year
- Calculates whether the current year is a leap year (365 or 366 days)
- Computes year progress percentage

### 2. Image Generation (Core Graphics)

Two separate images are rendered — one for light mode, one for dark mode.

**Canvas:** 3024 x 1964 pixels (optimized for Retina displays)

**Dot Grid Layout:**
- 37 columns x 10 rows
- Dot size: 38pt with 18pt gaps
- Corner radius: 8pt

**Dot Colors:**
| Dot Type | Light Mode | Dark Mode |
|----------|-----------|-----------|
| Past days | White | `#E8E8E8` |
| Today | Active dot color (configurable) | Active dot color |
| Future days | Background lightened 13% | Background lightened 13% |

**Label:** Username and progress percentage are rendered below the grid using Core Text.

### 3. HEIC Packaging

Both images are packaged into a single HEIC file with Apple's appearance metadata:

```
apple_desktop:apr = base64(bplist{ "l": 0, "d": 1 })
```

- Index 0 = light image
- Index 1 = dark image
- macOS reads this metadata and switches images based on system appearance

### 4. Wallpaper Registration

The wallpaper is registered with macOS through two methods:

1. **Finder AppleScript** — sets the desktop picture (updates System Settings preview)
2. **NSWorkspace** — applies to all connected screens

### 5. Aerials Manifest

DotCalendar registers itself in macOS's wallpaper manifest:
- Creates a thumbnail (400px wide) at `~/Library/Application Support/com.apple.wallpaper/aerials/thumbnails/`
- Adds an entry to `~/Library/Application Support/com.apple.wallpaper/aerials/manifest/entries.json`
- Restarts `WallpaperAgent` to reload the manifest

### 6. Scheduling

- A timer is set for the next midnight (00:01 Asia/Singapore)
- On wake from sleep, the app checks if midnight was missed and updates immediately
- The timer uses `RunLoop.main` for reliable firing under Swift Concurrency

## File Locations

| File | Path |
|------|------|
| Wallpaper HEIC | `~/Pictures/DotCalendar/wallpaper.heic` |
| Thumbnail | `~/Library/Application Support/com.apple.wallpaper/aerials/thumbnails/DOTCAL-001.png` |
| Manifest | `~/Library/Application Support/com.apple.wallpaper/aerials/manifest/entries.json` |
| Preferences | `UserDefaults` (standard) |
