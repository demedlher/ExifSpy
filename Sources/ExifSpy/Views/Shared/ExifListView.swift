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
    @Binding var scrollToGPS: Bool

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
                ScrollViewReader { proxy in
                    List {
                        ForEach(sections) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    ExifEntryRow(entry: entry)
                                }
                                // Show map buttons in GPS Data section
                                if section.title == "GPS Data", let coords = gpsCoordinates {
                                    MapButtonsRow(coordinates: coords)
                                        .id("appleMapsButton")
                                }
                            } header: {
                                SectionHeaderView(title: section.title, entries: section.entries)
                            }
                        }

                        // Copy All Metadata button
                        if !sections.isEmpty {
                            Section {
                                CopyAllButton(sections: sections)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: scrollToGPS) { shouldScroll in
                        if shouldScroll {
                            withAnimation {
                                // Anchor to align Apple Maps button with the arrow in the left pane
                                proxy.scrollTo("appleMapsButton", anchor: UnitPoint(x: 0.5, y: 0.55))
                            }
                            // Reset the trigger
                            DispatchQueue.main.async {
                                scrollToGPS = false
                            }
                        }
                    }
                }
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
    let entries: [ExifEntry]

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
            .contextMenu {
                Button {
                    copyToClipboard(formatSection(title: title, entries: entries))
                } label: {
                    Label("Copy Section", systemImage: "doc.on.doc")
                }
            }
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
        Group {
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
        .contextMenu {
            Button {
                copyToClipboard(entry.value)
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            Button {
                copyToClipboard("\(entry.key): \(entry.value)")
            } label: {
                Label("Copy Field", systemImage: "doc.on.doc.fill")
            }
        }
    }
}

/// Button to copy all metadata to clipboard
struct CopyAllButton: View {
    let sections: [ExifSectionData]
    @State private var copied = false

    var body: some View {
        Button {
            copyToClipboard(formatAllSections(sections))
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            HStack {
                Spacer()
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                Text(copied ? "Copied!" : "Copy All Metadata")
                Spacer()
            }
            .foregroundColor(copied ? .green : .accentColor)
        }
        .buttonStyle(.bordered)
        .padding(.vertical, 8)
    }
}

// MARK: - Clipboard Helpers

/// Copy text to the system clipboard
private func copyToClipboard(_ text: String) {
    #if canImport(AppKit)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    #endif
}

/// Format a single section for clipboard
private func formatSection(title: String, entries: [ExifEntry]) -> String {
    var result = "[\(title)]\n"
    for entry in entries {
        result += "\(entry.key): \(entry.value)\n"
    }
    return result
}

/// Format all sections for clipboard
private func formatAllSections(_ sections: [ExifSectionData]) -> String {
    sections.map { formatSection(title: $0.title, entries: $0.entries) }.joined(separator: "\n")
}
