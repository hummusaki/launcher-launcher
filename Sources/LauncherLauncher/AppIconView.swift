import AppKit
import SwiftUI

struct AppIconView: View {
    let launcher: Launcher
    var size: CGFloat = 56

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: launcher.path))
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
