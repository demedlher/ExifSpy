import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

/// Displays EXIF metadata sections in a scrollable list
struct ExifListView: View {
    let sections: [ExifSectionData]
    let isLoading: Bool
    let errorMessage: String?
    let hasFileStats: Bool
    let gpsCoordinates: GPSCoordinates?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading EXIF data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sections.isEmpty && hasFileStats {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No EXIF metadata found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.entries) { entry in
                                ExifEntryRow(entry: entry)
                            }
                            // Show map buttons in GPS Data section
                            if section.title == "GPS Data", let coords = gpsCoordinates {
                                MapButtonsRow(coordinates: coords)
                            }
                        } header: {
                            SectionHeaderView(title: section.title)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

/// Row with buttons to open location in maps and copy coordinates
struct MapButtonsRow: View {
    let coordinates: GPSCoordinates
    @State private var copiedFormat: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Map buttons row
            HStack(spacing: 12) {
                Button(action: openAppleMaps) {
                    Label("Apple Maps", systemImage: "map")
                }
                .buttonStyle(.bordered)

                Button(action: openGoogleMaps) {
                    Label("Google Maps", systemImage: "globe")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            // Copy buttons row
            HStack(spacing: 8) {
                Text("Copy:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                CopyButton(label: "Decimal", value: coordinates.decimalString, copiedFormat: $copiedFormat)
                CopyButton(label: "DMS", value: coordinates.dmsString, copiedFormat: $copiedFormat)
                CopyButton(label: "DDM", value: coordinates.ddmString, copiedFormat: $copiedFormat)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func openAppleMaps() {
        if let url = coordinates.appleMapsURL {
            #if canImport(AppKit)
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    private func openGoogleMaps() {
        if let url = coordinates.googleMapsURL {
            #if canImport(AppKit)
            NSWorkspace.shared.open(url)
            #endif
        }
    }
}

/// Small button to copy a coordinate format to clipboard
struct CopyButton: View {
    let label: String
    let value: String
    @Binding var copiedFormat: String?

    private var isCopied: Bool {
        copiedFormat == label
    }

    var body: some View {
        Button(action: copyToClipboard) {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(isCopied ? .green : .accentColor)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func copyToClipboard() {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)

        // Show checkmark briefly
        copiedFormat = label
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedFormat == label {
                copiedFormat = nil
            }
        }
        #endif
    }
}

/// Styled section header with dark background
struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.25, green: 0.3, blue: 0.4))
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
    }
}

/// Single row displaying an EXIF key-value pair
struct ExifEntryRow: View {
    let entry: ExifEntry

    /// Check if value contains newlines (nested structure)
    private var isMultiline: Bool {
        entry.value.contains("\n")
    }

    var body: some View {
        if isMultiline {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.key)
                    .foregroundColor(.primary)
                    .font(.body.weight(.medium))
                Text(entry.value)
                    .foregroundColor(.secondary)
                    .font(.callout)
                    .padding(.leading, 12)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: .top) {
                Text(entry.key)
                    .foregroundColor(.primary)
                Spacer()
                Text(entry.value)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .font(.body)
        }
    }
}
