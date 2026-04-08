import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(1)
        }
        .frame(width: 380, height: 420)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @State private var activeDotColor: Color = .red
    @State private var lightBgColor: Color = .blue
    @State private var darkBgColor: Color = .gray
    @State private var launchAtLogin = false
    @State private var showInMenuBar = true
    @State private var hasChanges = false

    var body: some View {
        Form {
            Section("Active Dot") {
                ColorPicker("Today's dot color", selection: $activeDotColor, supportsOpacity: false)
                    .onChange(of: activeDotColor) { hasChanges = true }
            }

            Section("Light Mode") {
                ColorPicker("Background", selection: $lightBgColor, supportsOpacity: false)
                    .onChange(of: lightBgColor) { hasChanges = true }
            }

            Section("Dark Mode") {
                ColorPicker("Background", selection: $darkBgColor, supportsOpacity: false)
                    .onChange(of: darkBgColor) { hasChanges = true }
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { hasChanges = true }
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                    .onChange(of: showInMenuBar) { hasChanges = true }
            }

            Section {
                HStack {
                    Button("Reset to Defaults") {
                        activeDotColor = Color(hex: "#E8483F")
                        lightBgColor = Color(hex: "#2D4976")
                        darkBgColor = Color(hex: "#525252")
                        launchAtLogin = false
                        hasChanges = true
                    }

                    Spacer()

                    Button("Apply") {
                        applyChanges()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!hasChanges && !engine.isUpdating)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { loadFromEngine() }
    }

    private func loadFromEngine() {
        activeDotColor = Color(hex: engine.activeDotHex)
        lightBgColor = Color(hex: engine.lightBgHex)
        darkBgColor = Color(hex: engine.darkBgHex)
        launchAtLogin = engine.launchAtLogin
        showInMenuBar = engine.showInMenuBar
        hasChanges = false
    }

    private func applyChanges() {
        engine.activeDotHex = activeDotColor.hexString
        engine.lightBgHex = lightBgColor.hexString
        engine.darkBgHex = darkBgColor.hexString
        engine.launchAtLogin = launchAtLogin
        engine.showInMenuBar = showInMenuBar
        engine.saveSettings()
        hasChanges = false

        Task { @MainActor in
            engine.generateAndApply()
        }
    }
}

// MARK: - About

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    // App icon + info
                    HStack(spacing: 12) {
                        Image(nsImage: {
                            // Try PNG first, then .icns, then app icon
                            if let path = Bundle.main.path(forResource: "icon_128x128", ofType: "png"),
                               let img = NSImage(contentsOfFile: path) {
                                return img
                            }
                            if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                               let img = NSImage(contentsOfFile: path) {
                                return img
                            }
                            return NSApp.applicationIconImage
                        }())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .cornerRadius(14)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DotCalendar")
                                .font(.system(size: 18, weight: .bold))
                            Text("Version \(version) (\(build))")
                                .font(.system(size: 10, weight: .thin))
                                .foregroundColor(.secondary)
                            Text("@suyadnyas")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        // Buttons
                        VStack(spacing: 8) {
                            Button("GitHub") {
                                NSWorkspace.shared.open(URL(string: "https://github.com/wibawasuyadnya")!)
                            }
                            .frame(width: 100)

                            Button("X.com") {
                                NSWorkspace.shared.open(URL(string: "https://x.com/itskadeks")!)
                            }
                            .frame(width: 100)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
        .environmentObject(WallpaperEngine.shared)
}
