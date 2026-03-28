import Foundation

struct Environment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var path: String
    var lastUsed: Date
    
    var corpusPath: String {
        return (path as NSString).appendingPathComponent("corpus")
    }
    
    var worksPath: String {
        return (corpusPath as NSString).appendingPathComponent("works")
    }
    
    var wikiPath: String {
        return (corpusPath as NSString).appendingPathComponent("wiki")
    }
}

struct EnvironmentConfig: Codable {
    var environments: [Environment]
    var defaultEditor: String
}
