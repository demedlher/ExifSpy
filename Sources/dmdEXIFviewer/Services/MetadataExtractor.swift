import Foundation
import ImageIO
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#endif

/// GPS coordinates extracted from image
struct GPSCoordinates {
    let latitude: Double
    let longitude: Double

    var appleMapsURL: URL? {
        // Use maps.apple.com with both ll (center) and q (pin) parameters
        URL(string: "https://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(latitude),\(longitude)")
    }

    var googleMapsURL: URL? {
        URL(string: "https://www.google.com/maps?q=\(latitude),\(longitude)")
    }
}

/// Result of metadata extraction
struct MetadataResult {
    let fileStats: FileStats
    let sections: [ExifSectionData]
    let previewImage: NSImage?
    let errorMessage: String?
    let gpsCoordinates: GPSCoordinates?
}

/// Service for extracting EXIF and image metadata
class MetadataExtractor {
    static let shared = MetadataExtractor()

    /// Debug mode for verbose logging
    var isDebugMode: Bool = false

    /// Known EXIF groups and their display titles
    private let knownExifGroups: [(key: CFString, title: String, isCoreGroup: Bool)] = [
        (kCGImagePropertyExifDictionary, "EXIF Details", true),
        (kCGImagePropertyTIFFDictionary, "TIFF Properties", true),
        (kCGImagePropertyGPSDictionary, "GPS Data", true),
        (kCGImagePropertyIPTCDictionary, "IPTC Information", false),
        (kCGImagePropertyJFIFDictionary, "JFIF Properties", false),
        (kCGImagePropertyPNGDictionary, "PNG Properties", false),
    ]

    private init() {}

    /// Extract metadata from a file path
    func extractMetadata(from path: String) -> MetadataResult {
        let imageUrl = URL(fileURLWithPath: path)
        let errorMessage: String? = nil
        var pixelWidth: Int? = nil
        var pixelHeight: Int? = nil
        var sections: [ExifSectionData] = []

        #if canImport(AppKit)
        let previewImage = NSImage(contentsOf: imageUrl)
        #else
        let previewImage: NSImage? = nil
        #endif

        // Try to create image source
        guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) else {
            let fileStats = createFileStats(url: imageUrl, path: path, pixelWidth: nil, pixelHeight: nil)
            return MetadataResult(
                fileStats: fileStats,
                sections: [],
                previewImage: previewImage,
                errorMessage: "Could not create image source.",
                gpsCoordinates: nil
            )
        }

        // Get image properties
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            let fileStats = createFileStats(url: imageUrl, path: path, pixelWidth: nil, pixelHeight: nil)
            return MetadataResult(
                fileStats: fileStats,
                sections: [],
                previewImage: previewImage,
                errorMessage: "Could not get image properties.",
                gpsCoordinates: nil
            )
        }

        // Extract pixel dimensions
        pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? Int
        pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? Int

        // Create file stats
        let fileStats = createFileStats(url: imageUrl, path: path, pixelWidth: pixelWidth, pixelHeight: pixelHeight)

        // Extract general image info
        var generalEntries: [ExifEntry] = []
        let topLevelKeysToDisplay: [CFString: String] = [
            kCGImagePropertyPixelWidth: "Pixel Width",
            kCGImagePropertyPixelHeight: "Pixel Height",
            kCGImagePropertyDPIWidth: "DPI Width",
            kCGImagePropertyDPIHeight: "DPI Height",
            kCGImagePropertyColorModel: "Color Model",
            kCGImagePropertyDepth: "Depth",
            kCGImagePropertyOrientation: "Orientation",
            kCGImagePropertyProfileName: "Color Profile"
        ]

        for (key, displayName) in topLevelKeysToDisplay {
            if let value = imageProperties[key] {
                generalEntries.append(ExifEntry(
                    key: displayName,
                    value: formatExifValue(rawValue: value, groupKey: key, entryKey: key)
                ))
            }
        }

        // Add other top-level properties
        imageProperties.forEach { key, value in
            if !knownExifGroups.contains(where: { $0.key == key }) &&
               !topLevelKeysToDisplay.keys.contains(key) &&
               !(value is NSDictionary) &&
               !generalEntries.contains(where: { $0.key == String(key) || $0.key == String(describing: key) }) {
                generalEntries.append(ExifEntry(
                    key: String(describing: key),
                    value: formatExifValue(rawValue: value, groupKey: key, entryKey: key)
                ))
            }
        }

        if !generalEntries.isEmpty {
            sections.append(ExifSectionData(
                title: "General Image Info",
                entries: generalEntries.sorted(by: { $0.key < $1.key })
            ))
        }

        // Extract known EXIF groups
        for groupInfo in knownExifGroups {
            if let groupDict = imageProperties[groupInfo.key] as? [CFString: Any], !groupDict.isEmpty {
                let entries = groupDict.map { (cfKey, rawValue) -> ExifEntry in
                    let keyString = String(cfKey)
                    if isDebugMode {
                        print("Processing key \(keyString) (Group: \(groupInfo.title))")
                    }
                    let displayValue = formatExifValue(rawValue: rawValue, groupKey: groupInfo.key, entryKey: cfKey)
                    return ExifEntry(key: keyString, value: displayValue)
                }
                if !entries.isEmpty {
                    sections.append(ExifSectionData(
                        title: groupInfo.title,
                        entries: entries.sorted(by: { $0.key < $1.key })
                    ))
                }
            }
        }

        // Extract GPS coordinates
        let gpsCoordinates = extractGPSCoordinates(from: imageProperties)

        return MetadataResult(
            fileStats: fileStats,
            sections: sections.filter { !$0.entries.isEmpty },
            previewImage: previewImage,
            errorMessage: errorMessage,
            gpsCoordinates: gpsCoordinates
        )
    }

    private func createFileStats(url: URL, path: String, pixelWidth: Int?, pixelHeight: Int?) -> FileStats {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = attributes[.size] as? NSNumber ?? 0
            let formattedSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
            let fileName = url.lastPathComponent
            let fileType = UTType(filenameExtension: url.pathExtension)?.localizedDescription ?? "Unknown"
            return FileStats(
                name: fileName,
                path: path,
                size: formattedSize,
                type: fileType,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight
            )
        } catch {
            return FileStats(
                name: url.lastPathComponent,
                path: path,
                size: "N/A",
                type: "Unknown",
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight
            )
        }
    }

    private func extractGPSCoordinates(from imageProperties: [CFString: Any]) -> GPSCoordinates? {
        guard let gpsDict = imageProperties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }

        guard let latitude = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
              let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String,
              let longitude = gpsDict[kCGImagePropertyGPSLongitude] as? Double,
              let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }

        // Convert to signed coordinates (N/E positive, S/W negative)
        let signedLatitude = latitudeRef == "S" ? -latitude : latitude
        let signedLongitude = longitudeRef == "W" ? -longitude : longitude

        return GPSCoordinates(latitude: signedLatitude, longitude: signedLongitude)
    }

    // MARK: - Value Formatting

    private func formatExifValue(rawValue: Any, groupKey: CFString, entryKey: CFString) -> String {
        var stringValue: String

        // GPS Version
        if groupKey == kCGImagePropertyGPSDictionary && entryKey == kCGImagePropertyGPSVersion {
            if let arrNum = rawValue as? [NSNumber] {
                stringValue = arrNum.map { $0.stringValue }.joined(separator: ".")
            } else if let arrInt = rawValue as? [Int] {
                stringValue = arrInt.map { String($0) }.joined(separator: ".")
            } else {
                stringValue = String(describing: rawValue)
            }
        }
        // EXIF Version
        else if groupKey == kCGImagePropertyExifDictionary && entryKey == kCGImagePropertyExifVersion {
            if let arrNum = rawValue as? [NSNumber] {
                stringValue = arrNum.map { $0.stringValue }.joined(separator: ".")
            } else if let arrInt = rawValue as? [Int] {
                stringValue = arrInt.map { String($0) }.joined(separator: ".")
            } else if let data = rawValue as? Data,
                      let versionString = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      versionString.count == 4,
                      versionString.allSatisfy({ $0.isASCII && $0.isNumber }) {
                let secondChar = versionString[versionString.index(versionString.startIndex, offsetBy: 1)]
                let thirdAndFourth = versionString.suffix(2)
                stringValue = "\(secondChar).\(thirdAndFourth)"
            } else if let data = rawValue as? Data,
                      let versionString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                stringValue = versionString
            } else {
                stringValue = String(describing: rawValue)
            }
        }
        // Lens Specification
        else if groupKey == kCGImagePropertyExifDictionary && entryKey == kCGImagePropertyExifLensSpecification {
            if let arrNum = rawValue as? [NSNumber], arrNum.count == 4 {
                let minFocal = arrNum[0].doubleValue
                let maxFocal = arrNum[1].doubleValue
                let minAperture = arrNum[2].doubleValue
                let focalStr = (minFocal == maxFocal) ? "\(formatNumber(minFocal))mm" : "\(formatNumber(minFocal))-\(formatNumber(maxFocal))mm"
                stringValue = "\(focalStr) f/\(formatNumber(minAperture))"
            } else if let arrNum = rawValue as? [NSNumber] {
                stringValue = arrNum.map { formatNumber($0.doubleValue) }.joined(separator: ", ")
            } else {
                stringValue = String(describing: rawValue)
            }
        }
        // String arrays
        else if let stringArray = rawValue as? [String] {
            let processedArray = stringArray.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let filteredArray = processedArray.filter { !$0.isEmpty }
            stringValue = filteredArray.joined(separator: ", ")
        }
        // Number arrays
        else if let numberArray = rawValue as? [NSNumber] {
            stringValue = numberArray.map { formatNumber($0.doubleValue) }.joined(separator: ", ")
        }
        // Int arrays
        else if let intArray = rawValue as? [Int] {
            stringValue = intArray.map { String($0) }.joined(separator: ", ")
        }
        // Data
        else if let data = rawValue as? Data {
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !str.isEmpty, str.containsPrintableCharacters() {
                stringValue = str
            } else if let str = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !str.isEmpty, str.containsPrintableCharacters() {
                stringValue = str
            } else {
                stringValue = "\(data.count) bytes"
            }
        }
        // Nested dictionary
        else if let dict = rawValue as? [String: Any] {
            stringValue = formatNestedDictionary(dict)
        }
        else if let dict = rawValue as? [CFString: Any] {
            let stringKeyDict = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
            stringValue = formatNestedDictionary(stringKeyDict)
        }
        else if let dict = rawValue as? NSDictionary {
            var stringKeyDict: [String: Any] = [:]
            for (key, value) in dict {
                stringKeyDict[String(describing: key)] = value
            }
            stringValue = formatNestedDictionary(stringKeyDict)
        }
        // Default
        else {
            stringValue = String(describing: rawValue)
        }

        return stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = (floor(number) == number) ? 0 : 2
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }

    private func formatNestedDictionary(_ dict: [String: Any]) -> String {
        // Filter out empty values and format each key-value pair
        let pairs = dict.compactMap { key, value -> String? in
            let formattedValue = formatSimpleValue(value)
            if formattedValue.isEmpty { return nil }
            return "\(key): \(formattedValue)"
        }.sorted()

        if pairs.isEmpty {
            return "(empty)"
        }
        return pairs.joined(separator: "\n")
    }

    private func formatSimpleValue(_ value: Any) -> String {
        if let str = value as? String {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let num = value as? NSNumber {
            return formatNumber(num.doubleValue)
        } else if let arr = value as? [String] {
            return arr.filter { !$0.isEmpty }.joined(separator: ", ")
        } else if let arr = value as? [NSNumber] {
            return arr.map { formatNumber($0.doubleValue) }.joined(separator: ", ")
        } else if let data = value as? Data {
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !str.isEmpty {
                return str
            }
            return "\(data.count) bytes"
        } else if let nestedDict = value as? [String: Any] {
            // For deeply nested, just show key count
            return "(\(nestedDict.count) fields)"
        } else {
            let str = String(describing: value)
            // Don't show empty or placeholder values
            if str.isEmpty || str == "(null)" || str == "<null>" {
                return ""
            }
            return str
        }
    }
}

// MARK: - String Extension

extension String {
    func containsPrintableCharacters() -> Bool {
        guard !self.isEmpty else { return false }
        let nonPrintableCount = self.unicodeScalars.lazy.filter { scalar -> Bool in
            !scalar.properties.isASCIIHexDigit &&
            !CharacterSet.alphanumerics.contains(scalar) &&
            !CharacterSet.whitespacesAndNewlines.contains(scalar) &&
            !CharacterSet.punctuationCharacters.contains(scalar) &&
            !CharacterSet.symbols.contains(scalar)
        }.count
        return Double(nonPrintableCount) / Double(self.unicodeScalars.count) < 0.3
    }
}
