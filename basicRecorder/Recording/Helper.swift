

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

func scaleChannelPower(power: Float) -> Float {
        let oldMax = 0.0
        let oldMin = -160.0
        let newMax = 100.0
        let newMin = 0.0
        
        let oldRange = oldMax - oldMin
        let newRange = newMax - newMin
        
        let newValue = (((Double(power) - oldMin) * newRange) / oldRange) + newMin
        
        return Float(newValue)
}

