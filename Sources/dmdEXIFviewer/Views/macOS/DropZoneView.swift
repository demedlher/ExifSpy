import SwiftUI
import AppKit

/// Initial drop zone view when no image is loaded
struct DropZoneView: View {
    @Binding var errorMessage: String?
    let isTargeted: Bool

    private var buildInfo: String {
        "v2.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)

            Text("dmd EXIF Viewer")
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
