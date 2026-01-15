import SwiftUI

/// Displays EXIF metadata sections in a scrollable list
struct ExifListView: View {
    let sections: [ExifSectionData]
    let isLoading: Bool
    let errorMessage: String?
    let hasFileStats: Bool

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
