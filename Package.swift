// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DotCalendar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "DotCalendar",
            path: "Sources",
            exclude: ["App/DotCalendarApp.swift"],
            resources: [
                .copy("../Resources/Assets.xcassets"),
                .copy("../Resources/Fonts")
            ]
        )
    ]
)
