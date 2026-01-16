import SwiftUI
import AppKit

/// Initial drop zone view when no image is loaded
struct DropZoneView: View {
    @Binding var errorMessage: String?
    let isTargeted: Bool

    private var buildInfo: String {
        "v2.1"
    }

    /// Load app icon from bundle or fall back to SF Symbol
    private var appIconImage: some View {
        Group {
            if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
               let nsImage = NSImage(contentsOf: iconURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            appIconImage
                .frame(width: 100, height: 100)

            Text("ExifSpy")
                .font(.title2)
                .fontWeight(.medium)

            Text("Drag and drop an image or video file")
                .font(.body)
                .foregroundColor(.secondary)

            if let errMsg = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errMsg)
                        .foregroundColor(.secondary)
                }
                .font(.callout)
                .padding(.top, 8)
            }

            Spacer()

            Text(buildInfo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .padding(20)
    }
}
