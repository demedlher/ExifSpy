import AppKit
import SwiftUI

// Create an NSImage from an SF Symbol
func createSymbolImage(name: String, size: CGFloat) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .large)
    let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
    return image.withSymbolConfiguration(config)!
}

// Save image to file
func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to create image data")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
    } catch {
        print("Error saving image: \(error)")
    }
}

// Main
let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = "./dmg_build/dmdEXIFviewer.app/Contents/Resources/AppIcon.iconset/"

// Create all icon sizes
for size in sizes {
    // Regular size
    let image = createSymbolImage(name: "camera.aperture", size: size * 0.8) // Slightly smaller to fit in the icon
    let path1 = "\(outputDir)icon_\(Int(size))x\(Int(size)).png"
    saveImage(image, to: path1)
    
    // @2x size
    let image2x = createSymbolImage(name: "camera.aperture", size: size * 2 * 0.8)
    let path2 = "\(outputDir)icon_\(Int(size))x\(Int(size))@2x.png"
    saveImage(image2x, to: path2)
}

print("Icons generated successfully")
