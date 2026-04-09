# Architecture

## Project Structure

```
DotCalendar/
├── Sources/
│   ├── App/
│   │   └── DotCalendarApp.swift       # App entry point + AppDelegate
│   ├── Models/
│   │   ├── WallpaperEngine.swift      # Core engine (generation, scheduling, settings)
│   │   └── AppError.swift             # Error types
│   ├── Views/
│   │   ├── SettingsView.swift         # Settings window (General + About tabs)
│   │   └── CalendarDisplayView.swift  # Menu bar popover view
│   └── Extensions/
│       └── Color+Hex.swift            # NSColor/Color hex conversion utilities
├── Resources/
│   ├── Assets.xcassets/               # Asset catalog
│   │   ├── AppIcon.appiconset/        # App icon (all sizes)
│   │   └── AccentColor.colorset/      # Accent color
│   ├── Fonts/                         # Custom fonts (reserved)
│   └── Screenshots/                   # App Store / README screenshots
├── Info.plist                         # Bundle configuration
├── Package.swift                      # Swift Package Manager manifest
├── AppIcon.icns                       # App icon (for build.sh)
├── build.sh                           # Build and packaging script
├── README.md
└── LICENSE
```

## MVC Pattern

### Model
- **WallpaperEngine** — singleton (`@MainActor`) that manages all state, settings, image generation, and wallpaper application. Acts as both model and service layer.
- **AppError** — error types for HEIC creation failures.

### View
- **SettingsView** — tabbed settings window with General (color pickers, toggles) and About (app info, links) tabs.
- **CalendarDisplayView** — menu bar popover showing the dot grid, progress bar, and action buttons.

### Controller
- **DotCalendarApp** — SwiftUI `@main` app with `MenuBarExtra` and `Settings` scenes.
- **AppDelegate** — handles single-instance enforcement, URL scheme, settings window management, and app reopen behavior.

## Key Design Decisions

### Single Instance
When a second instance launches, it sends a `DistributedNotification` to the running instance to show settings, then quits itself.

### Menu Bar App
`LSUIElement = true` in Info.plist — the app has no Dock icon and lives entirely in the menu bar.

### Settings Window
Uses `NSWindow` with `.floating` level to always appear on top. Created programmatically (not via SwiftUI Settings scene) for better control.

### HEIC Appearance
Uses Apple's undocumented `apple_desktop:apr` metadata to pack light and dark images into a single HEIC file. macOS switches between them automatically.

### Build System
Uses `swiftc` directly (not Xcode) for minimal build complexity. The `Package.swift` is provided for Xcode previews and development only.

## Dependencies

None. DotCalendar uses only Apple frameworks:
- SwiftUI, AppKit, CoreGraphics, ImageIO, CoreText
- ServiceManagement (Launch at Login)
- os (Logging)
