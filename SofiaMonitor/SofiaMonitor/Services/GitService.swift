import Foundation

class GitService {
    let workingDirectory: String
    
    init(workingDirectory: String) {
        self.workingDirectory = workingDirectory
    }
    
    func hasUncommittedChanges() -> Bool {
        let output = runGit(["status", "--porcelain"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func getUncommittedFiles() -> [String] {
        let output = runGit(["status", "--porcelain"])
        return output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.count > 3 {
                    return String(trimmed.dropFirst(3))
                }
                return nil
            }
    }
    
    func commit(files: [String], message: String) -> Bool {
        // Stage files
        for file in files {
            _ = runGit(["add", file])
        }
        
        // Commit
        let output = runGit(["commit", "-m", message])
        return !output.contains("nothing to commit")
    }
    
    func autoCommit(file: String, prefix: String = "auto") -> Bool {
        let filename = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let workName = extractWorkName(from: file)
        let message = "\(prefix): \(workName) \(filename) @ \(timestamp)"
        
        return commit(files: [file], message: message)
    }
    
    private func extractWorkName(from path: String) -> String {
        // Extract work name from path like corpus/works/frankenstein/chapters/01.md
        let components = path.components(separatedBy: "/")
        if let worksIndex = components.firstIndex(of: "works"),
           worksIndex + 1 < components.count {
            return components[worksIndex + 1]
        }
        return "unknown"
    }
    
    private func runGit(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
