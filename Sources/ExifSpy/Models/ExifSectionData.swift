import Foundation

/// Represents a group of related EXIF entries (e.g., "GPS Data", "EXIF Details")
struct ExifSectionData: Identifiable {
    let id = UUID()
    let title: String
    var entries: [ExifEntry]
}
