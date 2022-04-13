

import Foundation
import AVFoundation
import SwiftUI

func getCreationDate (for file: URL) -> Date {
    if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
       let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
        return creationDate
    } else {
        return Date()
    }
}

func normalizeSoundLevel(level: Float) -> CGFloat {
    let level = max(0.2, CGFloat(level) + 50) / 2
    return CGFloat(level * (300/25))
}

