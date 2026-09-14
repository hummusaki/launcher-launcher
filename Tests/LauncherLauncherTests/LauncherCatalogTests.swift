import Testing
@testable import LauncherLauncher

@Test func knownLaunchersAreDetected() {
    #expect(LauncherCatalog.looksLikeLauncher(name: "Whisky", bundleIdentifier: nil))
    #expect(LauncherCatalog.looksLikeLauncher(name: "Steam", bundleIdentifier: "com.valvesoftware.steam"))
    #expect(LauncherCatalog.looksLikeLauncher(name: "Mythic", bundleIdentifier: nil))
}

@Test func unrelatedAppsAreIgnored() {
    #expect(!LauncherCatalog.looksLikeLauncher(name: "Calculator", bundleIdentifier: "com.apple.calculator"))
}
