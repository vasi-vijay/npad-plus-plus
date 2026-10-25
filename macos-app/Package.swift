// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// Detect if XCTest.framework is present (Xcode.app vs Apple Command Line Tools)
let isXCTestAvailable: Bool = {
    let candidatePaths = [
        "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework",
        "/Library/Developer/CommandLineTools/Library/Frameworks/XCTest.framework",
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/XCTest.framework"
    ]
    for path in candidatePaths {
        if FileManager.default.fileExists(atPath: path) {
            return true
        }
    }
    if let devDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"],
       FileManager.default.fileExists(atPath: "\(devDir)/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework") {
        return true
    }
    return false
}()

var packageTargets: [Target] = [
    .executableTarget(
        name: "NotepadPlusMac",
        dependencies: [],
        path: "Sources/NotepadPlusMac",
        exclude: [
            "Resources/Info.plist",
            "Resources/AppIcon.icns",
            "Resources/AppIcon.iconset"
        ],
        swiftSettings: [
            .unsafeFlags(["-O"])
        ]
    )
]

if isXCTestAvailable {
    packageTargets.append(
        .testTarget(
            name: "NotepadPlusMacTests",
            dependencies: ["NotepadPlusMac"],
            path: "Tests/NotepadPlusMacTests"
        )
    )
}

let package = Package(
    name: "NotepadPlusMac",
    platforms: [
        .macOS(.v14) // Target macOS 14 Sonoma and later (Apple Silicon M1/M2/M3/M4 optimized)
    ],
    products: [
        .executable(
            name: "NotepadPlusMac",
            targets: ["NotepadPlusMac"]
        ),
    ],
    dependencies: [
        // Pure native standard library, AppKit and SwiftUI for maximum performance on Apple Silicon ARM64
    ],
    targets: packageTargets
)

