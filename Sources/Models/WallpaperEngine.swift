import AppKit
import CoreGraphics
import ImageIO
import os
import ServiceManagement

private let log = Logger(subsystem: "com.aguswibawa.dotcalendar", category: "engine")

// MARK: - WallpaperEngine

@MainActor
final class WallpaperEngine: ObservableObject {
    static let shared = WallpaperEngine()

    // Customizable colors (stored as hex)
    @Published var activeDotHex: String
    @Published var lightBgHex: String
    @Published var darkBgHex: String
    @Published var launchAtLogin: Bool

    @Published var showInMenuBar: Bool
    @Published var lastUpdate: Date?
    @Published var isUpdating = false
    @Published var dayOfYear: Int = 1
    @Published var totalDays: Int = 365
    @Published var yearProgress: Double = 0

    private var timer: Timer?
    private let defaults = UserDefaults.standard

    // Constants
    private let width = 3024
    private let height = 1964
    private let cols = 37
    private let rows = 10
    private let dotSize: CGFloat = 38
    private let gap: CGFloat = 18
    private let cornerRadius: CGFloat = 8

    // Paths
    private let wallpaperDir: URL
    private let wallpaperPath: URL

    init() {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        wallpaperDir = pictures.appendingPathComponent("DotCalendar")
        wallpaperPath = wallpaperDir.appendingPathComponent("wallpaper.heic")

        activeDotHex = defaults.string(forKey: "activeDotHex") ?? "#E8483F"
        lightBgHex = defaults.string(forKey: "lightBgHex") ?? "#2D4976"
        darkBgHex = defaults.string(forKey: "darkBgHex") ?? "#525252"
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showInMenuBar = defaults.object(forKey: "showInMenuBar") as? Bool ?? true
        updateDateInfo()
    }

    private func updateDateInfo() {
        let (day, year) = getCurrentDay()
        let total = isLeapYear(year) ? 366 : 365
        dayOfYear = day
        totalDays = total
        yearProgress = Double(day) / Double(total) * 100
    }

    // MARK: - Settings

    func saveSettings() {
        defaults.set(activeDotHex, forKey: "activeDotHex")
        defaults.set(lightBgHex, forKey: "lightBgHex")
        defaults.set(darkBgHex, forKey: "darkBgHex")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showInMenuBar, forKey: "showInMenuBar")

        // Update login item
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            log.error("Failed to update login item: \(error.localizedDescription)")
        }
    }

    func resetDefaults() {
        activeDotHex = "#E8483F"
        lightBgHex = "#2D4976"
        darkBgHex = "#525252"
        saveSettings()
    }

    // MARK: - Scheduling

    func scheduleNextUpdate() {
        timer?.invalidate()

        let tz = TimeZone(identifier: "Asia/Singapore")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let now = Date()

        // Target next 00:01:00 in Asia/Singapore
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 1
        components.second = 0

        guard var target = cal.date(from: components) else { return }

        // If today's 00:01 has already passed, target tomorrow's 00:01
        if target <= now {
            guard let next = cal.date(byAdding: .day, value: 1, to: target) else { return }
            target = next
        }

        let interval = target.timeIntervalSince(now)
        log.info("Next wallpaper update in \(Int(interval))s (at \(target))")

        // Use Timer() + RunLoop.main.add() for reliable firing under Swift Concurrency
        let t = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.generateAndApply()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - Wake from Sleep

    func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // If we crossed midnight while sleeping, update immediately
                let currentDay = self.getCurrentDay().dayOfYear
                if currentDay != self.dayOfYear {
                    self.generateAndApply()
                    return // generateAndApply already reschedules
                }
                // Always reschedule in case the timer was lost during sleep
                self.scheduleNextUpdate()
            }
        }
    }

    // MARK: - Date Calculation

    private func getCurrentDay() -> (dayOfYear: Int, year: Int) {
        let tz = TimeZone(identifier: "Asia/Singapore")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let now = Date()
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now)!
        let year = cal.component(.year, from: now)
        return (dayOfYear, year)
    }

    private func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    // MARK: - Generate & Apply

    func generateAndApply() {
        isUpdating = true
        updateDateInfo()
        log.info("Starting wallpaper generation")

        try? FileManager.default.createDirectory(at: wallpaperDir, withIntermediateDirectories: true)

        let (dayOfYear, year) = getCurrentDay()
        let totalDays = isLeapYear(year) ? 366 : 365
        let username = NSUserName()

        log.info("Day \(dayOfYear)/\(totalDays) of \(year)")

        let lightBg = NSColor(hex: lightBgHex)
        let darkBg = NSColor(hex: darkBgHex)
        let activeDot = NSColor(hex: activeDotHex)

        let lightImage = generateImage(
            bg: lightBg, past: NSColor.white, today: activeDot,
            future: lightBg.lightened(by: 0.13),
            dayOfYear: dayOfYear, totalDays: totalDays, username: username)

        let darkImage = generateImage(
            bg: darkBg, past: NSColor(hex: "#E8E8E8"), today: activeDot,
            future: darkBg.lightened(by: 0.13),
            dayOfYear: dayOfYear, totalDays: totalDays, username: username)

        guard let light = lightImage, let dark = darkImage else {
            log.error("Failed to generate images")
            isUpdating = false
            return
        }

        do {
            try createAppearanceHEIC(light: light, dark: dark, outputURL: wallpaperPath)
            log.info("Saved HEIC to \(self.wallpaperPath.path)")
        } catch {
            log.error("Failed to create HEIC: \(error.localizedDescription)")
            isUpdating = false
            return
        }

        updateThumbnail(from: light)
        registerInManifest()

        if setWallpaper(path: wallpaperPath.path) {
            log.info("Wallpaper applied successfully")
            lastUpdate = Date()
        } else {
            log.error("Failed to apply wallpaper")
        }

        isUpdating = false
        scheduleNextUpdate()
    }

    // MARK: - Aerials Manifest Integration

    private let categoryID = "DC000000-0000-0000-0000-D07CA1E0DA21"
    private let assetID = "DC000001-0000-0000-0000-D07CA1E0DA21"

    private var thumbnailPath: String {
        NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/aerials/thumbnails/DOTCAL-001.png"
    }

    private var manifestPath: String {
        NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/aerials/manifest/entries.json"
    }

    private func updateThumbnail(from image: CGImage) {
        // Scale down to 400px wide thumbnail
        let scale = 400.0 / CGFloat(image.width)
        let thumbW = 400
        let thumbH = Int(CGFloat(image.height) * scale)

        guard let ctx = CGContext(
            data: nil, width: thumbW, height: thumbH,
            bitsPerComponent: 8, bytesPerRow: thumbW * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: thumbW, height: thumbH))

        guard let thumbImage = ctx.makeImage() else { return }

        let url = URL(fileURLWithPath: thumbnailPath)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, thumbImage, nil)
        CGImageDestinationFinalize(dest)

        log.info("Updated thumbnail")
    }

    private func registerInManifest() {
        guard FileManager.default.fileExists(atPath: manifestPath) else {
            log.error("Manifest not found")
            return
        }

        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: manifestPath)),
              var manifest = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            log.error("Cannot read manifest")
            return
        }

        let thumbURL = "file://" + thumbnailPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        let wallpaperURL = "file://" + wallpaperPath.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!

        // Build category
        let category: [String: Any] = [
            "id": categoryID,
            "localizedDescriptionKey": "DotCalendar",
            "localizedNameKey": "DotCalendar",
            "preferredOrder": 99,
            "previewImage": thumbURL,
            "representativeAssetID": assetID,
            "subcategories": [] as [[String: Any]]
        ]

        // Build asset
        let asset: [String: Any] = [
            "accessibilityLabel": "DotCalendar",
            "categories": [categoryID],
            "id": assetID,
            "includeInShuffle": false,
            "localizedNameKey": "DotCalendar",
            "pointsOfInterest": [:] as [String: Any],
            "preferredOrder": 1,
            "previewImage": thumbURL,
            "shotID": "DOTCAL-001",
            "showInTopLevel": true,
            "subcategories": [] as [String],
            "url-4K-SDR-240FPS": wallpaperURL
        ]

        // Remove old entries
        var categories = manifest["categories"] as? [[String: Any]] ?? []
        categories.removeAll { ($0["id"] as? String) == categoryID }
        categories.append(category)
        manifest["categories"] = categories

        var assets = manifest["assets"] as? [[String: Any]] ?? []
        assets.removeAll { ($0["id"] as? String) == assetID }
        assets.append(asset)
        manifest["assets"] = assets

        // Write back
        guard let newData = try? JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]) else {
            log.error("Cannot serialize manifest")
            return
        }

        do {
            try newData.write(to: URL(fileURLWithPath: manifestPath))
            log.info("Updated aerials manifest with DotCalendar entry")
        } catch {
            log.error("Cannot write manifest: \(error.localizedDescription)")
        }

        // Restart WallpaperAgent to reload manifest
        let kill = Process()
        kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        kill.arguments = ["WallpaperAgent"]
        try? kill.run()
        kill.waitUntilExit()
    }

    // MARK: - Image Generation

    private func generateImage(bg: NSColor, past: NSColor, today: NSColor, future: NSColor,
                               dayOfYear: Int, totalDays: Int, username: String) -> CGImage? {
        let w = width
        let h = height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let cell = dotSize + gap
        let gridW = CGFloat(cols) * cell - gap
        let actualRows = (totalDays + cols - 1) / cols
        let gridH = CGFloat(actualRows) * cell - gap
        let offsetX = (CGFloat(w) - gridW) / 2
        let offsetY = (CGFloat(h) - gridH) / 2

        // Fill background (CG origin is bottom-left)
        ctx.setFillColor(bg.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        // Draw dots (flip row so row 0 is at top visually)
        for i in 0..<totalDays {
            let col = i % cols
            let row = i / cols
            let x = offsetX + CGFloat(col) * cell
            // In bottom-left coords: top row (row=0) → highest y
            let y = CGFloat(h) - offsetY - CGFloat(row) * cell - dotSize

            let dayNum = i + 1
            let color: CGColor
            if dayNum < dayOfYear { color = past.cgColor }
            else if dayNum == dayOfYear { color = today.cgColor }
            else { color = future.cgColor }

            ctx.setFillColor(color)
            let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
            let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            ctx.addPath(path)
            ctx.fillPath()
        }

        // Draw label text with Core Text
        let percentage = Double(dayOfYear) / Double(totalDays) * 100
        let label = String(format: "%@ • %.1f%%", username, percentage)

        let font = CTFontCreateUIFontForLanguage(.system, 30, nil)!
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: past.cgColor
        ]
        let attrStr = CFAttributedStringCreate(kCFAllocatorDefault, label as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let textBounds = CTLineGetBoundsWithOptions(line, [])

        // Position text centered, below the grid
        let gridBottomBL = CGFloat(h) - offsetY - gridH // bottom of grid in BL coords
        let textX = (CGFloat(w) - textBounds.width) / 2
        let textY = gridBottomBL - 100 // 100px gap below grid

        ctx.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(line, ctx)

        return ctx.makeImage()
    }

    // MARK: - HEIC Creation with Appearance Metadata

    private func createAppearanceHEIC(light: CGImage, dark: CGImage, outputURL: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(
            outputURL as CFURL, "public.heic" as CFString, 2, nil
        ) else {
            throw AppError.heicCreationFailed
        }

        // Build apple_desktop:apr metadata (binary plist, base64 encoded)
        let appearanceDict: [String: Int] = ["l": 0, "d": 1]
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: appearanceDict, format: .binary, options: 0)
        let base64 = plistData.base64EncodedString()

        // Create CGImageMetadata with apple_desktop namespace
        let metadata = CGImageMetadataCreateMutable()
        let ns = "http://ns.apple.com/namespace/1.0/" as CFString
        let prefix = "apple_desktop" as CFString

        guard CGImageMetadataRegisterNamespaceForPrefix(metadata, ns, prefix, nil) else {
            throw AppError.metadataFailed
        }

        guard let tag = CGImageMetadataTagCreate(
            ns, prefix, "apr" as CFString, .string, base64 as CFTypeRef
        ) else {
            throw AppError.metadataFailed
        }

        CGImageMetadataSetTagWithPath(metadata, nil, "apple_desktop:apr" as CFString, tag)

        // Add light image (index 0) with metadata
        let props = [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary
        CGImageDestinationAddImageAndMetadata(dest, light, metadata, props)

        // Add dark image (index 1)
        CGImageDestinationAddImage(dest, dark, props)

        guard CGImageDestinationFinalize(dest) else {
            throw AppError.heicFinalizeFailed
        }
    }

    // MARK: - Set Wallpaper

    private func setWallpaper(path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)

        // 1. Set via Finder AppleScript (classic, reliable, updates Settings preview)
        let finderScript = """
        tell application "Finder"
            set desktop picture to POSIX file "\(path)"
        end tell
        """
        if let appleScript = NSAppleScript(source: finderScript) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                log.error("Finder AppleScript failed: \(error)")
            } else {
                log.info("Wallpaper set via Finder")
            }
        }

        // 2. Use NSWorkspace for all screens
        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(fileURL, for: screen, options: [:])
            } catch {
                log.error("NSWorkspace failed for screen: \(error.localizedDescription)")
            }
        }
        log.info("Wallpaper set via NSWorkspace for \(NSScreen.screens.count) screen(s)")

        return true
    }
}
