import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

/// Image preview with click-to-zoom support
struct ImagePreviewView: View {
    let image: NSImage?
    let fileStats: FileStats?
    let onImageTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image preview
            imagePreview
                .frame(maxHeight: .infinity)

            // File information
            if let stats = fileStats {
                fileInfoSection(stats: stats)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onTapGesture { onImageTap() }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .help("Click to zoom")
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Preview")
                            .foregroundColor(.secondary)
                    }
                )
        }
    }

    @ViewBuilder
    private func fileInfoSection(stats: FileStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File Information")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                fileInfoRow(label: "Name", value: stats.name)
                fileInfoRow(label: "Path", value: stats.path, truncate: true)
                fileInfoRow(label: "Size", value: stats.size)
                if let dimensions = stats.dimensionsDisplay {
                    fileInfoRow(label: "Dimensions", value: dimensions)
                }
                fileInfoRow(label: "Type", value: stats.type)
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private func fileInfoRow(label: String, value: String, truncate: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            if truncate {
                Text(value)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text(value)
            }
        }
    }
}
