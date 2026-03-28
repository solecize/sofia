import Foundation

class StatsService {
    
    static func getWorks(for environment: Environment) -> [Work] {
        let worksPath = environment.worksPath
        var works: [Work] = []
        
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: worksPath) else {
            return works
        }
        
        for workName in contents.sorted() {
            if workName.hasPrefix(".") { continue }
            
            let workPath = (worksPath as NSString).appendingPathComponent(workName)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: workPath, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            
            let chaptersPath = (workPath as NSString).appendingPathComponent("chapters")
            
            // Count chapters and words
            var chapterCount = 0
            var wordCount = 0
            
            if let chapters = try? FileManager.default.contentsOfDirectory(atPath: chaptersPath) {
                for chapter in chapters {
                    if chapter.hasSuffix(".md") && !chapter.hasPrefix(".") {
                        chapterCount += 1
                        let chapterPath = (chaptersPath as NSString).appendingPathComponent(chapter)
                        if let content = try? String(contentsOfFile: chapterPath, encoding: .utf8) {
                            wordCount += content.split(separator: " ").count
                        }
                    }
                }
            }
            
            // Get phase from profile
            let profilePath = (workPath as NSString).appendingPathComponent(".sofia/profile.md")
            var phase = "unknown"
            if let content = try? String(contentsOfFile: profilePath, encoding: .utf8) {
                if let range = content.range(of: #"current_phase\s*=\s*"([^"]+)""#, options: .regularExpression) {
                    let match = content[range]
                    if let quoteStart = match.firstIndex(of: "\""),
                       let quoteEnd = match.lastIndex(of: "\"") {
                        phase = String(match[match.index(after: quoteStart)..<quoteEnd])
                    }
                }
            }
            
            // Find last modified and recent files
            var lastModified = Date.distantPast
            var recentFiles: [(Date, String)] = []
            
            if let enumerator = FileManager.default.enumerator(atPath: workPath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasPrefix(".") || file.contains("/.") { continue }
                    if !file.hasSuffix(".md") { continue }
                    
                    let filePath = (workPath as NSString).appendingPathComponent(file)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                       let mtime = attrs[.modificationDate] as? Date {
                        if mtime > lastModified {
                            lastModified = mtime
                        }
                        recentFiles.append((mtime, file))
                    }
                }
            }
            
            // Sort and get top 3
            recentFiles.sort { $0.0 > $1.0 }
            let topRecent = recentFiles.prefix(3).map { $0.1 }
            
            let work = Work(
                name: workName,
                path: workPath,
                wordCount: wordCount,
                chapterCount: chapterCount,
                phase: phase,
                lastModified: lastModified,
                recentFiles: Array(topRecent)
            )
            works.append(work)
        }
        
        return works
    }
}
