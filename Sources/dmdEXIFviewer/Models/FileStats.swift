import Foundation

/// File information and statistics
struct FileStats {
    let name: String
    let path: String
    let size: String
    let type: String
    let pixelWidth: Int?
    let pixelHeight: Int?

    /// Standard aspect ratios to check against (width:height)
    private static let standardRatios: [(name: String, w: Int, h: Int)] = [
        ("1:1", 1, 1),
        ("5:4", 5, 4),
        ("4:3", 4, 3),
        ("3:2", 3, 2),
        ("16:10", 16, 10),
        ("5:3", 5, 3),
        ("16:9", 16, 9),
        ("2:1", 2, 1),
        ("21:9", 21, 9),
        // Portrait versions
        ("4:5", 4, 5),
        ("3:4", 3, 4),
        ("2:3", 2, 3),
        ("10:16", 10, 16),
        ("3:5", 3, 5),
        ("9:16", 9, 16),
        ("1:2", 1, 2),
        ("9:21", 9, 21),
    ]

    /// Calculates the aspect ratio as a simplified string (e.g., "16:9")
    var aspectRatio: String? {
        guard let w = pixelWidth, let h = pixelHeight, w > 0, h > 0 else { return nil }

        let actualRatio = Double(w) / Double(h)

        // Check for standard ratios (within 1% tolerance)
        for standard in Self.standardRatios {
            let standardRatio = Double(standard.w) / Double(standard.h)
            let difference = abs(actualRatio - standardRatio) / standardRatio
            if difference < 0.01 {
                return standard.name
            }
        }

        // Fall back to GCD reduction
        let divisor = gcd(w, h)
        let reducedW = w / divisor
        let reducedH = h / divisor

        // If reduced ratio is still large numbers, show approximate
        if reducedW > 100 || reducedH > 100 {
            return String(format: "%.2f:1", actualRatio)
        }

        return "\(reducedW):\(reducedH)"
    }

    /// Formatted dimensions string with aspect ratio and total pixels
    var dimensionsDisplay: String? {
        guard let w = pixelWidth, let h = pixelHeight else { return nil }
        var result = "\(w) x \(h) pixels"
        if let ratio = aspectRatio {
            result += " (\(ratio))"
        }
        result += ", \(formattedTotalPixels)"
        return result
    }

    /// Total pixel count formatted as K, M, or G
    private var formattedTotalPixels: String {
        guard let w = pixelWidth, let h = pixelHeight else { return "" }
        let total = Double(w) * Double(h)

        if total >= 1_000_000_000 {
            return String(format: "%.1fG pixels", total / 1_000_000_000)
        } else if total >= 1_000_000 {
            return String(format: "%.1fM pixels", total / 1_000_000)
        } else if total >= 1_000 {
            return String(format: "%.0fK pixels", total / 1_000)
        } else {
            return "\(Int(total)) pixels"
        }
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var numA = abs(a)
        var numB = abs(b)
        if numB == 0 { return numA }
        if numA == 0 { return numB }
        while numB != 0 {
            let temp = numB
            numB = numA % numB
            numA = temp
        }
        return numA
    }
}
