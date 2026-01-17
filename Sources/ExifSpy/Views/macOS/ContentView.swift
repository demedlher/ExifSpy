import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Main content view for macOS
struct ContentView: View {
    @State private var imagePath: String? = nil
    @State private var previewImage: NSImage? = nil
    @State private var fileStats: FileStats? = nil
    @State private var exifSections: [ExifSectionData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var isTargeted: Bool = false
    @State private var showZoomOverlay: Bool = false
    @State private var gpsCoordinates: GPSCoordinates? = nil
    @State private var scrollToGPS: Bool = false

    var body: some View {
        ZStack {
            mainContent
                .frame(minWidth: 600, minHeight: 700)
                .background(Color(NSColor.windowBackgroundColor))
                .onDrop(of: [UTType.image, UTType.movie, UTType.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if imagePath != nil {
                            Button(action: clearImage) {
                                Image(systemName: "xmark.circle")
                            }
                            .help("Clear image")
                        }
                    }
                }

            // Zoom overlay
            if showZoomOverlay, let image = previewImage {
                ImageZoomOverlay(image: image) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showZoomOverlay = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showZoomOverlay)
    }

    @ViewBuilder
    private var mainContent: some View {
        if isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if imagePath != nil {
            splitView
        } else {
            DropZoneView(errorMessage: $errorMessage, isTargeted: isTargeted)
        }
    }

    @ViewBuilder
    private var splitView: some View {
        HSplitView {
            // Left pane - Image preview
            ImagePreviewView(
                image: previewImage,
                fileStats: fileStats,
                gpsCoordinates: gpsCoordinates,
                onImageTap: {
                    if previewImage != nil {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showZoomOverlay = true
                        }
                    }
                },
                onScrollToGPS: {
                    scrollToGPS = true
                }
            )
            .frame(minWidth: 200, idealWidth: 280, maxWidth: 400)

            // Right pane - EXIF data
            ExifListView(
                sections: exifSections,
                isLoading: isLoading,
                errorMessage: errorMessage,
                hasFileStats: fileStats != nil,
                gpsCoordinates: gpsCoordinates,
                scrollToGPS: $scrollToGPS
            )
            .frame(minWidth: 300)
        }
    }

    // MARK: - Actions

    private func clearImage() {
        imagePath = nil
        previewImage = nil
        fileStats = nil
        exifSections = []
        errorMessage = nil
        isLoading = false
        showZoomOverlay = false
        gpsCoordinates = nil
        scrollToGPS = false
    }

    private func handleDrop(providers: [NSItemProvider]) {
        clearImage()
        isLoading = true

        guard let provider = providers.first else {
            errorMessage = "No file provider found"
            isLoading = false
            return
        }

        let supportedTypes = [
            UTType.fileURL.identifier,
            UTType.movie.identifier,
            UTType.image.identifier,
            "public.mpeg-4",
            "public.audiovisual-content"
        ]

        for typeId in supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(typeId) {
                provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Error loading file: \(error.localizedDescription)"
                            self.isLoading = false
                            return
                        }

                        if let url = item as? URL {
                            self.loadImage(from: url.path)
                        } else if let data = item as? Data,
                                  let urlString = String(data: data, encoding: .utf8),
                                  let url = URL(string: urlString), url.isFileURL {
                            self.loadImage(from: url.path)
                        } else if typeId == UTType.image.identifier, let nsImage = item as? NSImage {
                            self.processDroppedImage(nsImage)
                        } else {
                            self.errorMessage = "Could not process the dropped file"
                            self.isLoading = false
                        }
                    }
                }
                return
            }
        }

        errorMessage = "Unsupported file type"
        isLoading = false
    }

    private func processDroppedImage(_ nsImage: NSImage) {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("\(UUID().uuidString).jpg")

        if let imageData = nsImage.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: imageData),
           let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) {
            do {
                try jpegData.write(to: tempFile)
                loadImage(from: tempFile.path)
            } catch {
                errorMessage = "Could not process image data"
                isLoading = false
            }
        } else {
            errorMessage = "Could not process image data"
            isLoading = false
        }
    }

    private func loadImage(from path: String) {
        imagePath = path

        DispatchQueue.global(qos: .userInitiated).async {
            let result = MetadataExtractor.shared.extractMetadata(from: path)

            DispatchQueue.main.async {
                self.previewImage = result.previewImage
                self.fileStats = result.fileStats
                self.exifSections = result.sections
                self.errorMessage = result.errorMessage
                self.gpsCoordinates = result.gpsCoordinates
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
