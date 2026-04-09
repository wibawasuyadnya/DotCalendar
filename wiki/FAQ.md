# FAQ

## General

### Why does the wallpaper not change with light/dark mode?

Make sure the wallpaper appearance is set to **Automatic** in System Settings > Wallpaper. DotCalendar generates a single HEIC file with both variants — macOS handles the switching.

### Why is the version showing incorrect numbers in About?

If you're running from Xcode, it may pick up Xcode's bundle info instead of DotCalendar's. Build with `./build.sh` and run the app from `build/DotCalendar.app` for correct version info.

### Can I change the timezone?

Currently, the timezone is hardcoded to `Asia/Singapore`. To change it, edit `WallpaperEngine.swift` and replace all instances of `"Asia/Singapore"` with your preferred timezone identifier (e.g., `"America/New_York"`).

### Does it work on Intel Macs?

The build script targets `arm64` (Apple Silicon) only. To build for Intel, change `-target arm64-apple-macos14.0` to `-target x86_64-apple-macos14.0` in `build.sh`. For a universal binary, you would need to compile both and use `lipo` to merge them.

## Troubleshooting

### The wallpaper doesn't appear in System Settings

1. Make sure the app has run at least once (check for `~/Pictures/DotCalendar/wallpaper.heic`)
2. The aerials manifest may need to be refreshed — click **Update** in the menu bar popover
3. Try restarting WallpaperAgent: `killall WallpaperAgent`

### The app icon shows a generic icon in About

This happens when running from Xcode. Build with `./build.sh` and the correct icon will appear.

### Settings window doesn't appear

- Try Cmd+Space, type "DotCalendar", and press Enter
- Or use the URL scheme: open `dotcalendar://` in Safari
- The settings window floats above other windows — check all Spaces

### The wallpaper didn't update at midnight

- If your Mac was asleep, the update happens on wake
- Check Console.app for logs with subsystem `app.dotcalendar`
- Try clicking **Update** manually in the menu bar popover

## Privacy & Security

### What permissions does DotCalendar need?

- **Desktop Pictures access** — to set the wallpaper
- **Automation (Finder)** — for AppleScript wallpaper setting (macOS will prompt on first use)

### Does it phone home?

No. DotCalendar has zero network access. Everything runs locally.

### Where is my data stored?

| Data | Location |
|------|----------|
| Wallpaper | `~/Pictures/DotCalendar/wallpaper.heic` |
| Preferences | UserDefaults (standard) |
| Thumbnail | `~/Library/Application Support/com.apple.wallpaper/aerials/thumbnails/` |
