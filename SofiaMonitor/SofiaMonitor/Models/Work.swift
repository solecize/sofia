import Foundation

struct Work: Identifiable {
    var id: String { name }
    var name: String
    var path: String
    var wordCount: Int
    var chapterCount: Int
    var phase: String
    var lastModified: Date
    var recentFiles: [String]
    
    var lastEditDescription: String {
        let delta = Date().timeIntervalSince(lastModified)
        if delta < 60 {
            return "\(Int(delta))s ago"
        } else if delta < 3600 {
            return "\(Int(delta / 60))m ago"
        } else if delta < 86400 {
            return "\(Int(delta / 3600))h ago"
        } else {
            return "\(Int(delta / 86400))d ago"
        }
    }
    
    var hasRecentChanges: Bool {
        return Date().timeIntervalSince(lastModified) < 60
    }
}

struct ChangeEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date
    var environmentName: String
    var workName: String
    var filePath: String
    var commitMessage: String
    var isReviewed: Bool = false
}

struct Changelog: Codable {
    var version: String = "1.0"
    var events: [ChangeEvent] = []
}
