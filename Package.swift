// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeStatusBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeStatusBar",
            targets: ["ClaudeStatusBar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeStatusBar",
            path: "ClaudeStatusBar",
            exclude: [
                "Info.plist",
                "ClaudeStatusBar.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "ClaudeStatusBarTests",
            dependencies: ["ClaudeStatusBar"],
            path: "ClaudeStatusBarTests"
        )
    ]
)
