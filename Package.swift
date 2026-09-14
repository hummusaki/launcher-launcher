// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LauncherLauncher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LauncherLauncher", targets: ["LauncherLauncher"])
    ],
    targets: [
        .executableTarget(name: "LauncherLauncher"),
        .testTarget(name: "LauncherLauncherTests", dependencies: ["LauncherLauncher"])
    ]
)
