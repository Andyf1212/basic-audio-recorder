import Foundation

struct Recording {
    let fileURL: URL
    let createdAt: Date
    var processingToggle: Bool = false
}
