import SwiftUI

// MARK: - Calendar Display View (Menu Bar Popover)

struct CalendarDisplayView: View {
    @EnvironmentObject var engine: WallpaperEngine

    private let cols = 37
    private let dotSize: CGFloat = 6
    private let dotGap: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("DotCalendar")
                    .font(.headline)
                Spacer()
                Text("Day \(engine.dayOfYear) of \(engine.totalDays)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Dot grid
            dotGridView(dayOfYear: engine.dayOfYear, totalDays: engine.totalDays)

            // Progress bar
            HStack(spacing: 8) {
                ProgressView(value: Double(engine.dayOfYear), total: Double(engine.totalDays))
                    .tint(Color(hex: engine.activeDotHex))
                Text(String(format: "%.1f%%", engine.yearProgress))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }

            Divider()

            // Last update
            if let lastUpdate = engine.lastUpdate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(lastUpdate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.caption)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    Task { @MainActor in
                        engine.generateAndApply()
                    }
                } label: {
                    Label(engine.isUpdating ? "Updating..." : "Update", systemImage: "arrow.clockwise")
                }
                .disabled(engine.isUpdating)

                Spacer()

                SettingsLink {
                    Label("Settings", systemImage: "gear")
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 340)
    }

    private func dotGridView(dayOfYear: Int, totalDays: Int) -> some View {
        let rows = (totalDays + cols - 1) / cols
        let cell = dotSize + dotGap
        let gridW = CGFloat(cols) * cell - dotGap
        let gridH = CGFloat(rows) * cell - dotGap
        let activeDot = engine.activeDotHex

        return Canvas { context, size in
            for i in 0..<totalDays {
                let col = i % cols
                let row = i / cols
                let x = CGFloat(col) * cell
                let y = CGFloat(row) * cell

                let dayNum = i + 1
                let color: Color
                if dayNum < dayOfYear {
                    color = .primary.opacity(0.3)
                } else if dayNum == dayOfYear {
                    color = Color(hex: activeDot)
                } else {
                    color = .primary.opacity(0.08)
                }

                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                let path = RoundedRectangle(cornerRadius: 1.5).path(in: rect)
                context.fill(path, with: .color(color))
            }
        }
        .frame(width: gridW, height: gridH)
    }
}

#Preview {
    CalendarDisplayView()
        .environmentObject(WallpaperEngine.shared)
}
