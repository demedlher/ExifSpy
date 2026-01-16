import Foundation

/// Represents a single EXIF metadata key-value pair
struct ExifEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}
