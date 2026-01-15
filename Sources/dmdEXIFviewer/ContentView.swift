import SwiftUI
import UniformTypeIdentifiers // For UTType
import ImageIO              // For EXIF data extraction
import AppKit               // For NSImage
import Foundation           // For DateFormatter

// Struct to hold individual EXIF entries
struct ExifEntry: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

// Struct to hold a section of EXIF data
struct ExifSectionData: Identifiable {
    let id = UUID()
    let title: String
    var entries: [ExifEntry]
}

// Struct to hold file statistics
struct FileStats {
    let name: String
    let path: String
    let size: String // Formatted size
    let type: String
    let pixelWidth: Int?
    let pixelHeight: Int?
}

struct ContentView: View {
    @State private var imagePath: String? = nil
    @State private var previewImage: NSImage? = nil
    @State private var fileStats: FileStats? = nil
    @State private var exifSections: [ExifSectionData] = []
    
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var isTargeted: Bool = false
    @State private var localDebugMode: Bool = false
    
    // Make debug mode a static property
    static var isDebugMode: Bool = false

    // Define known EXIF groups and their display titles
    private let knownExifGroups: [(key: CFString, title: String, isCoreGroup: Bool)] = [
        (kCGImagePropertyExifDictionary, "EXIF Details", true),
        (kCGImagePropertyTIFFDictionary, "TIFF Properties", true),
        (kCGImagePropertyGPSDictionary, "GPS Data", true),
        (kCGImagePropertyIPTCDictionary, "IPTC Information", false),
        (kCGImagePropertyJFIFDictionary, "JFIF Properties", false),
        (kCGImagePropertyPNGDictionary, "PNG Properties", false),
    ]

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading image details...")
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if imagePath != nil { // Check if an image is loaded
                HStack {
                    LeftPaneView(previewImage: previewImage, fileStats: fileStats)
                    RightPaneView(exifSections: exifSections, isLoading: isLoading, errorMessage: errorMessage, fileStats: fileStats)
                }
            } else { // Drop Zone UI
                DropZoneView(errorMessage: $errorMessage)
            }
            
            if ContentView.isDebugMode {
                HStack {
                    Toggle("Debug Mode", isOn: $localDebugMode)
                        .onChange(of: localDebugMode) { newValue in
                            ContentView.isDebugMode = newValue
                        }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .frame(minWidth: 750, minHeight: 550)
        .background(isTargeted ? Color.blue.opacity(0.1) : Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isTargeted ? Color.blue : Color.gray.opacity(0.5),
                              style: StrokeStyle(lineWidth: isTargeted ? 3 : 2, dash: [isTargeted ? 0 : 6]))
        )
        .padding()
        .onDrop(of: [UTType.image, UTType.movie], isTargeted: $isTargeted) { providers -> Bool in
            handleDrop(providers: providers)
            return true
        }
        .onChange(of: imagePath) { newValue in
            if let path = newValue {
                isLoading = true
                errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    loadImageDetails(from: path)
                    isLoading = false
                }
            } else {
                previewImage = nil
                fileStats = nil
                exifSections = []
                errorMessage = nil
                isLoading = false
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        self.imagePath = nil
        self.errorMessage = nil
        self.isLoading = true

        guard let provider = providers.first else {
            self.errorMessage = "No file provider found"
            self.isLoading = false
            return
        }
        
        print("Handling drop with provider types: \(provider.registeredTypeIdentifiers)")
        
        // First try to get the file URL for any file type
        let supportedTypes = [
            UTType.fileURL.identifier,
            UTType.movie.identifier,
            UTType.image.identifier,
            "public.mpeg-4",
            "public.mpeg-4-audio",
            "public.audiovisual-content",
            "public.movie"
        ]
        
        for typeId in supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(typeId) {
                print("Attempting to load as type: \(typeId)")
                provider.loadItem(forTypeIdentifier: typeId, options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error loading item: \(error.localizedDescription)")
                            self.errorMessage = "Error loading file: \(error.localizedDescription)"
                            self.isLoading = false
                            return
                        }
                        
                        if let url = item as? URL {
                            print("Successfully loaded file URL: \(url.path)")
                            self.imagePath = url.path
                            return
                        } else if let data = item as? Data, let urlString = String(data: data, encoding: .utf8),
                                  let url = URL(string: urlString), url.isFileURL {
                            print("Successfully loaded file from data: \(url.path)")
                            self.imagePath = url.path
                            return
                        } else if typeId == UTType.image.identifier, let image = item as? NSImage {
                            print("Processing direct image drop")
                            self.processDroppedImage(image)
                            return
                        }
                        
                        // If we get here, we couldn't process the item
                        print("Could not process item of type: \(typeId)")
                        print("Item type: \(type(of: item))")
                        self.errorMessage = "Could not process the dropped file"
                        self.isLoading = false
                    }
                }
                return
            }
        }
        
        // If we get here, no supported types were found
        print("Unsupported file type. Available types: \(provider.registeredTypeIdentifiers)")
        self.errorMessage = "Unsupported file type"
        self.isLoading = false
    }
    
    private func processDroppedImage(_ nsImage: NSImage) {
        print("Processing dropped image")
        self.previewImage = nsImage
        
        // Create a temporary file path for the image
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("\(UUID().uuidString).jpg")
        
        // Save the image to a temporary file
        if let imageData = nsImage.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: imageData),
           let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) {
            
            do {
                try jpegData.write(to: tempFile)
                print("Saved temporary image to: \(tempFile.path)")
                self.imagePath = tempFile.path
            } catch {
                print("Failed to save temporary image: \(error)")
                self.errorMessage = "Could not process image data"
                self.isLoading = false
            }
        } else {
            self.errorMessage = "Could not process image data"
            self.isLoading = false
        }

        // The file loading is now handled by the code above
    }

    private func loadImageDetails(from path: String) {
        self.previewImage = nil
        self.fileStats = nil
        self.exifSections = []
        var localErrorMessage: String? = nil

        let imageUrl = URL(fileURLWithPath: path)
        self.previewImage = NSImage(contentsOf: imageUrl)

        // Initialize pixel dimensions to nil before attempting to read them
        var pixelWidth: Int? = nil
        var pixelHeight: Int? = nil

        // Attempt to get image properties to extract pixel dimensions and other metadata
        guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) else {
            self.errorMessage = (localErrorMessage ?? "") + "\nCould not create image source."
            // Try to set file stats even if image source fails, but pixel dimensions might be unavailable
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                let fileSize = attributes[.size] as? NSNumber ?? 0
                let formattedSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
                let fileName = imageUrl.lastPathComponent
                let fileType = UTType(filenameExtension: imageUrl.pathExtension)?.localizedDescription ?? "Unknown"
                self.fileStats = FileStats(name: fileName, path: path, size: formattedSize, type: fileType, 
                                           pixelWidth: nil, // Explicitly nil as imageSource failed
                                           pixelHeight: nil)
            } catch {
                // If both imageSource and file attributes fail, this error might overwrite the imageSource one
                localErrorMessage = (localErrorMessage == nil ? "" : localErrorMessage! + "\n") + "Could not load file attributes: \(error.localizedDescription)"
                self.errorMessage = localErrorMessage
            }
            return
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            self.errorMessage = (localErrorMessage ?? "") + "\nCould not get image properties."
            // Similar to above, try to set file stats
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: path)
                let fileSize = attributes[.size] as? NSNumber ?? 0
                let formattedSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
                let fileName = imageUrl.lastPathComponent
                let fileType = UTType(filenameExtension: imageUrl.pathExtension)?.localizedDescription ?? "Unknown"
                self.fileStats = FileStats(name: fileName, path: path, size: formattedSize, type: fileType, 
                                           pixelWidth: nil, 
                                           pixelHeight: nil)
            } catch {
                localErrorMessage = (localErrorMessage == nil ? "" : localErrorMessage! + "\n") + "Could not load file attributes: \(error.localizedDescription)"
                self.errorMessage = localErrorMessage
            }
            return
        }

        // Extract pixel dimensions from the successfully retrieved imageProperties
        pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? Int
        pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? Int

        // Now set fileStats with all available information
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let fileSize = attributes[.size] as? NSNumber ?? 0
            let formattedSize = ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
            let fileName = imageUrl.lastPathComponent
            let fileType = UTType(filenameExtension: imageUrl.pathExtension)?.localizedDescription ?? "Unknown"
            self.fileStats = FileStats(name: fileName, path: path, size: formattedSize, type: fileType, 
                                       pixelWidth: pixelWidth, 
                                       pixelHeight: pixelHeight)
        } catch {
            print("Error getting file attributes: \(error)")
            localErrorMessage = (localErrorMessage == nil ? "" : localErrorMessage! + "\n") + "Could not load file attributes: \(error.localizedDescription)"
            // File stats might be partially set if pixel dimensions were found but attributes fail
            // This case needs careful handling of self.fileStats if it was already partially set
            if self.fileStats == nil { // Only create new if not set at all
                self.fileStats = FileStats(name: imageUrl.lastPathComponent, path: path, size: "N/A", type: "Unknown",
                                           pixelWidth: pixelWidth, pixelHeight: pixelHeight)
            }
        }
        
        var tempSections: [ExifSectionData] = []

        var generalEntries: [ExifEntry] = []
        let topLevelKeysToDisplay: [CFString: String] = [
            kCGImagePropertyPixelWidth: "Pixel Width", kCGImagePropertyPixelHeight: "Pixel Height",
            kCGImagePropertyDPIWidth: "DPI Width", kCGImagePropertyDPIHeight: "DPI Height",
            kCGImagePropertyColorModel: "Color Model", kCGImagePropertyDepth: "Depth",
            kCGImagePropertyOrientation: "Orientation", kCGImagePropertyProfileName: "Color Profile"
        ]
        for (key, displayName) in topLevelKeysToDisplay {
            if let value = imageProperties[key] {
                generalEntries.append(ExifEntry(key: displayName, value: formatExifValue(rawValue: value, groupKey: key, entryKey: key)))
            }
        }
        imageProperties.forEach { key, value in
            if !knownExifGroups.contains(where: { $0.key == key }) &&
               !topLevelKeysToDisplay.keys.contains(key) &&
               !(value is NSDictionary) && 
               !generalEntries.contains(where: {$0.key == String(key) || $0.key == String(describing: key) }) {
                generalEntries.append(ExifEntry(key: String(describing: key), value: formatExifValue(rawValue: value, groupKey: key, entryKey: key)))
            }
        }
        if !generalEntries.isEmpty {
            tempSections.append(ExifSectionData(title: "General Image Info", entries: generalEntries.sorted(by: { $0.key < $1.key })))
        }

        // Diagnostic print for the entire imageProperties dictionary
        // print("All image properties: \(imageProperties)")

        for groupInfo in knownExifGroups {
            if let groupDict = imageProperties[groupInfo.key] as? [CFString: Any], !groupDict.isEmpty {
                let entries = groupDict.map { (cfKey, rawValue) -> ExifEntry in
                    let keyString = String(cfKey)
                    if ContentView.isDebugMode {
                        print("loadImageDetails: Processing key \(keyString) (Group: \(groupInfo.title))")
                        print("  Raw value type: \(type(of: rawValue))")
                        print("  Raw value description: \(rawValue)")
                    }
                    
                    let displayValue = formatExifValue(rawValue: rawValue, groupKey: groupInfo.key, entryKey: cfKey)
                    if ContentView.isDebugMode {
                        print("loadImageDetails: Formatted value for key \(keyString): \(displayValue)")
                    }
                    return ExifEntry(key: keyString, value: displayValue)
                }
                if !entries.isEmpty {
                    tempSections.append(ExifSectionData(title: groupInfo.title, entries: entries.sorted(by: { $0.key < $1.key })))
                }
            }
        }
        
        self.exifSections = tempSections.filter { !$0.entries.isEmpty }

        if self.exifSections.isEmpty && self.fileStats != nil {
            // UI handles "No metadata found"
        }
        self.errorMessage = localErrorMessage
    }

}

// View for the initial drop zone
struct DropZoneView: View {
    @Binding var errorMessage: String? // Share error message state
    
    private let buildInfo: String = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let dateString = formatter.string(from: Date())
        return "v1.0 • \(dateString)"
    }()

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.bottom)
            Text("dmd EXIF viewer")
                .font(.title)
            Text("Drag and drop an image or video file here.")
                .foregroundColor(.secondary)
            if let errMsg = errorMessage {
                Text("Error: \(errMsg)")
                    .foregroundColor(.red)
                    .padding(.top)
            }
            Spacer()
            Text(buildInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// View for the Left Pane (Preview and Stats)
struct LeftPaneView: View {
    let previewImage: NSImage?
    let fileStats: FileStats?

    // Helper function to calculate Greatest Common Divisor (GCD)
    private func gcd(_ a: Int, _ b: Int) -> Int {
        var numA = abs(a)
        var numB = abs(b)
        if numB == 0 { return numA } // GCD(a,0) = |a|
        if numA == 0 { return numB } // GCD(0,b) = |b|
        while numB != 0 {
            let temp = numB
            numB = numA % numB
            numA = temp
        }
        return numA
    }

    // Helper to calculate and format aspect ratio
    private func formatAspectRatio(width: Int?, height: Int?) -> String {
        guard let w = width, let h = height, w > 0, h > 0 else { return "" }
        let commonDivisor = gcd(w, h)
        return " (\(w / commonDivisor):\(h / commonDivisor))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let previewImage = previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .padding(.bottom)
            } else {
                Rectangle().fill(Color.gray.opacity(0.1))
                    .frame(maxHeight: 200).cornerRadius(8)
                    .overlay(Text("No Preview").foregroundColor(.gray))
                    .padding(.bottom)
            }

            if let stats = fileStats {
                Text("File Information").font(.headline)
                Group {
                    Text("Name: \(stats.name)")
                    Text("Path: \(stats.path)").lineLimit(1).truncationMode(.middle)
                    Text("Size: \(stats.size)")
                    if let w = stats.pixelWidth, let h = stats.pixelHeight {
                        Text("Dimensions: \(w) x \(h) pixels" + formatAspectRatio(width: w, height: h))
                    }
                    Text("Type: \(stats.type)")
                }.font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
    }
}

// View for the Right Pane (EXIF data)
struct RightPaneView: View {
    let exifSections: [ExifSectionData]
    let isLoading: Bool
    let errorMessage: String?
    let fileStats: FileStats?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading EXIF data...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if exifSections.isEmpty && fileStats != nil {
                Text("No EXIF metadata found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(exifSections) { section in
                        Section(header: StyledSectionHeaderView(title: section.title)) {
                            ForEach(section.entries) { entry in
                                ExifEntryRowView(entry: entry)
                            }
                        }
                    }
                }
            }
        }
    }
}

// New View for displaying a single EXIF section
struct ExifSectionView: View {
    let sectionData: ExifSectionData

    var body: some View {
        Section {
            if sectionData.entries.isEmpty {
                Text("No data in this section.")
                    .foregroundColor(.gray)
                    .padding(.vertical, 5)
            } else {
                ForEach(Array(sectionData.entries.enumerated()), id: \.offset) { index, entry in
                    ExifEntryRowView(entry: entry)
                        .listRowBackground(index % 2 == 0 ? Color.clear : Color(NSColor.windowBackgroundColor).opacity(0.3))
                }
            }
        } header: {
            StyledSectionHeaderView(title: sectionData.title) // Use the new dedicated header view
        }
    }
}

// New dedicated View for styled section headers
struct StyledSectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.medium))
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.05, green: 0.15, blue: 0.35))
            .cornerRadius(4)
    }
}

// New View for displaying a single EXIF entry row
struct ExifEntryRowView: View {
    let entry: ExifEntry

    var body: some View {
        HStack {
            Text(entry.key)
            Spacer()
            Text(entry.value)
                .onAppear {
                    if ContentView.isDebugMode {
                        print("ExifEntryRowView: Displaying value for key \(entry.key): \(entry.value)")
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Helper function to format EXIF values based on type and key
func formatExifValue(rawValue: Any, groupKey: CFString, entryKey: CFString) -> String {
    if ContentView.isDebugMode {
        print("formatExifValue: Received rawValue: '\(rawValue)', Type: \(type(of: rawValue)), groupKey: '\(groupKey)', entryKey: '\(entryKey)'")
    }
    var stringValue: String

    // Key-specific formatting takes precedence
    if groupKey == kCGImagePropertyGPSDictionary && entryKey == kCGImagePropertyGPSVersion {
        if let arrNum = rawValue as? [NSNumber] {
            stringValue = arrNum.map { $0.stringValue }.joined(separator: ".")
        } else if let arrInt = rawValue as? [Int] {
            stringValue = arrInt.map { String($0) }.joined(separator: ".")
        } else {
            stringValue = String(describing: rawValue)
        }
    } else if groupKey == kCGImagePropertyExifDictionary && entryKey == kCGImagePropertyExifVersion {
        if ContentView.isDebugMode {
            print("formatExifValue: EXIFVersion block. Raw value: \(rawValue), Type: \(type(of: rawValue))")
        }
        
        // First try to handle as array of numbers
        if let arrNum = rawValue as? [NSNumber] {
            stringValue = arrNum.map { $0.stringValue }.joined(separator: ".")
            if ContentView.isDebugMode {
                print("formatExifValue: EXIFVersion processed as NSNumber array: \(stringValue)")
            }
        } else if let arrInt = rawValue as? [Int] {
            stringValue = arrInt.map { String($0) }.joined(separator: ".")
            if ContentView.isDebugMode {
                print("formatExifValue: EXIFVersion processed as Int array: \(stringValue)")
            }
        // Fallback to existing Data processing
        } else if let data = rawValue as? Data,
           let versionString = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines),
           versionString.count == 4,
           versionString.allSatisfy({ $0.isASCII && $0.isNumber }) {
            let secondChar = versionString[versionString.index(versionString.startIndex, offsetBy: 1)]
            let thirdAndFourth = versionString.suffix(2)
            stringValue = "\(secondChar).\(thirdAndFourth)"
            if ContentView.isDebugMode {
                print("formatExifValue: EXIFVersion processed as ASCII Data: \(stringValue)")
            }
        } else if let data = rawValue as? Data, let versionString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            stringValue = versionString
            if ContentView.isDebugMode {
                print("formatExifValue: EXIFVersion processed as UTF-8 Data: \(stringValue)")
            }
        } else {
            stringValue = String(describing: rawValue)
            if ContentView.isDebugMode {
                print("formatExifValue: EXIFVersion fallback to String(describing:): \(stringValue)")
            }
        }
    } else if groupKey == kCGImagePropertyExifDictionary && entryKey == kCGImagePropertyExifLensSpecification {
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
    else if let stringArray = rawValue as? [String] {
        if ContentView.isDebugMode {
            print("formatExifValue: String array block. Original array for key \(entryKey): \(stringArray)")
        }
        let processedArray = stringArray.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let filteredArray = processedArray.filter { !$0.isEmpty }
        stringValue = filteredArray.joined(separator: ", ")
        if ContentView.isDebugMode {
            print("formatExifValue: Final formatted string for key \(entryKey): \(stringValue)")
        }
    } else if let numberArray = rawValue as? [NSNumber] {
        stringValue = numberArray.map { formatNumber($0.doubleValue) }.joined(separator: ", ")
    } else if let intArray = rawValue as? [Int] {
        stringValue = intArray.map { String($0) }.joined(separator: ", ")
    } else if let data = rawValue as? Data {
        if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty, str.containsPrintableCharacters() {
            stringValue = str
        } else if let str = String(data: data, encoding: .ascii)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty, str.containsPrintableCharacters() {
            stringValue = str
        } else {
            stringValue = "\(data.count) bytes"
        }
    } else {
        stringValue = String(describing: rawValue)
    }

    return stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
}

// Helper for number formatting
func formatNumber(_ number: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = (floor(number) == number) ? 0 : 2
    return formatter.string(from: NSNumber(value: number)) ?? String(number)
}

// Helper to check if string is mostly printable
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