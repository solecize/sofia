import SwiftUI
import ServiceManagement

// =============================================================================
// COMMAND-LINE COMPILATION NOTES
// =============================================================================
// This app can be built without Xcode using swiftc:
//
//   cd SofiaMonitor && swiftc -o SofiaMonitorApp \
//     -framework SwiftUI -framework AppKit -framework Foundation \
//     SofiaMonitor/SofiaMonitorApp.swift \
//     SofiaMonitor/Models/Environment.swift \
//     SofiaMonitor/Models/Work.swift \
//     SofiaMonitor/Views/MenuBarView.swift \
//     SofiaMonitor/Views/PreferencesView.swift \
//     SofiaMonitor/Services/GitService.swift \
//     SofiaMonitor/Services/StatsService.swift \
//     SofiaMonitor/Services/FileWatcher.swift
//
// IMPORTANT: When compiling with swiftc (not Xcode):
// 1. #Preview macros must be commented out (they require PreviewsMacros plugin)
// 2. Asset catalogs (Assets.xcassets) are NOT available - use embedded resources
// 3. The menu bar icon SVG is embedded below as a string
// 4. Output filename must differ from directory name (use SofiaMonitorApp not SofiaMonitor)
//
// To run: ./SofiaMonitorApp &
// =============================================================================

// Menu bar icon SVG embedded as string (required for command-line compilation)
// NSImage doesn't parse SVG directly, so we fall back to system symbol
let menuBarIconSVG = """
<svg version="1.0" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 22 22">
<circle style="fill:#FFFFFF;" cx="8.5" cy="14.5" r="0.5"/>
<path style="fill:#FFFFFF;" d="M7.068,15.49c-0.008-0.025-0.017-0.049-0.023-0.074C7.016,15.281,7,15.143,7,15c0-0.854,0.538-1.578,1.291-1.865c-1.677-0.571-3.464,0.819-3.296,2.534c-0.09,1.471,2.186,3.199,4.004,1.834c0.187-0.152,0.463-0.387,0.557-0.592C9.378,16.964,9.194,17,9,17C8.065,17,7.287,16.356,7.068,15.49z"/>
<circle style="fill:#FFFFFF;" cx="15.5" cy="14.5" r="0.5"/>
<path style="fill:#FFFFFF;" d="M14.068,15.49c-0.008-0.025-0.017-0.049-0.023-0.074C14.016,15.281,14,15.143,14,15c0-0.854,0.538-1.578,1.291-1.865c-1.677-0.571-3.464,0.819-3.296,2.534c-0.09,1.471,2.186,3.199,4.004,1.834c0.187-0.152,0.463-0.387,0.557-0.592C16.378,16.964,16.194,17,16,17C15.065,17,14.287,16.356,14.068,15.49z"/>
<path style="fill:#FFFFFF;" d="M17.959,6.664c-0.391,0.155-1.464,0.697-2.04,0.992c-0.184,0.094-0.405-0.018-0.432-0.223c-0.077-0.574-0.215-1.558-0.274-1.741c-0.048-0.151-0.2-0.239-0.354-0.202c-0.343,0.082-1.301,0.873-1.725,1.234c-0.119,0.101-0.293,0.092-0.403-0.019l-1.471-2.471C11.188,4.163,11.094,4.14,11,4.148c-0.094-0.008-0.188,0.015-0.259,0.087L9.269,6.706c-0.11,0.11-0.284,0.12-0.403,0.019C8.442,6.364,7.485,5.573,7.141,5.491C6.987,5.454,6.835,5.542,6.787,5.693C6.729,5.876,6.591,6.86,6.513,7.434C6.486,7.639,6.265,7.75,6.081,7.656c-0.576-0.295-1.648-0.837-2.04-0.992C3.876,6.599,3.706,6.738,3.74,6.912c0.205,1.059,0.862,4.39,1.001,4.321C6.202,10.509,8.477,10,10.975,10c0.008,0,0.017,0.001,0.025,0.001S11.017,10,11.025,10c2.498,0,4.773,0.509,6.234,1.233c0.14,0.069,0.796-3.262,1.001-4.321C18.294,6.738,18.124,6.599,17.959,6.664z M5.5,10C5.224,10,5,9.776,5,9.5C5,9.224,5.224,9,5.5,9S6,9.224,6,9.5C6,9.776,5.776,10,5.5,10z M7.5,9C7.224,9,7,8.776,7,8.5C7,8.224,7.224,8,7.5,8S8,8.224,8,8.5C8,8.776,7.776,9,7.5,9z M11,9c-0.552,0-1-0.672-1-1.5S10.448,6,11,6s1,0.672,1,1.5S11.552,9,11,9z M14.5,9C14.224,9,14,8.776,14,8.5C14,8.224,14.224,8,14.5,8S15,8.224,15,8.5C15,8.776,14.776,9,14.5,9z M16.5,10C16.224,10,16,9.776,16,9.5C16,9.224,16.224,9,16.5,9S17,9.224,17,9.5C17,9.776,16.776,10,16.5,10z"/>
</svg>
"""

func createMenuBarIcon() -> NSImage {
    guard let data = menuBarIconSVG.data(using: .utf8),
          let image = NSImage(data: data) else {
        return NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Sofia")!
    }
    image.isTemplate = true
    image.size = NSSize(width: 18, height: 18)
    return image
}

// AppDelegate to manage activation policy
// Menu bar apps need to become "regular" apps temporarily to show preferences
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct SofiaMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(nsImage: createMenuBarIcon())
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            PreferencesView()
                .environmentObject(appState)
                .onAppear {
                    // Show in dock when preferences open
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .onDisappear {
                    // Hide from dock when preferences close
                    NSApp.setActivationPolicy(.accessory)
                }
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var environments: [Environment] = []
    @Published var activeEnvironment: Environment?
    @Published var pendingChanges: Int = 0
    @Published var isWatching: Bool = false
    @Published var isLocked: Bool = false
    
    // Editor preferences
    @AppStorage("environmentEditor") var environmentEditor: String = "windsurf"
    @AppStorage("documentEditor") var documentEditor: String = "system"
    
    // Writing Organization Mode
    @AppStorage("writingModeEnabled") var writingModeEnabled: Bool = false
    
    // Launch at Login
    var launchAtLogin: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            objectWillChange.send()
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
                }
            }
        }
    }
    
    private var fileWatcher: FileWatcher?
    private var gitService: GitService?
    
    // Known editors with their CLI paths
    static let environmentEditors: [(name: String, id: String, path: String)] = [
        ("Windsurf", "windsurf", "/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf"),
        ("Cursor", "cursor", "/Applications/Cursor.app/Contents/Resources/app/bin/cursor"),
        ("VS Code", "vscode", "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"),
        ("OS Default", "system", "")
    ]
    
    static let documentEditors: [(name: String, id: String, path: String)] = [
        ("Typora", "typora", "/Applications/Typora.app"),
        ("iA Writer", "iawriter", "/Applications/iA Writer.app"),
        ("Obsidian", "obsidian", "/Applications/Obsidian.app"),
        ("OS Default", "system", "")
    ]
    
    // File extensions for each category
    static let documentExtensions: Set<String> = ["md", "txt", "rtf", "markdown"]
    static let environmentExtensions: Set<String> = ["swift", "sh", "json", "toml", "yml", "yaml", "py", "js", "ts", "jsx", "tsx"]
    
    var statusIcon: String {
        if pendingChanges > 0 {
            return "circle.fill"
        } else if isWatching {
            return "circle.fill"
        } else {
            return "circle"
        }
    }
    
    var statusColor: Color {
        if pendingChanges > 0 {
            return .blue
        } else if isWatching {
            return .green
        } else {
            return .secondary
        }
    }
    
    var environmentEditorName: String {
        Self.environmentEditors.first(where: { $0.id == environmentEditor })?.name ?? "Editor"
    }
    
    var documentEditorName: String {
        Self.documentEditors.first(where: { $0.id == documentEditor })?.name ?? "Editor"
    }
    
    // Get the OS default app name for a file type
    static func defaultAppName(for fileExtension: String) -> String? {
        let tempURL = URL(fileURLWithPath: "/tmp/test.\(fileExtension)")
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: tempURL) else {
            return nil
        }
        return appURL.deletingPathExtension().lastPathComponent
    }
    
    static var osDefaultDocumentApp: String {
        defaultAppName(for: "md") ?? "Finder"
    }
    
    static var osDefaultDirectoryApp: String {
        "Finder"
    }
    
    // Rules file name based on environment editor
    var rulesFileName: String {
        switch environmentEditor {
        case "cursor": return ".cursorrules"
        case "vscode": return ".github/copilot-instructions.md"
        default: return ".windsurfrules"
        }
    }
    
    // Embedded writing rules template (so it works in any environment)
    static let writingRulesTemplate = """
# Sofia Writing Organization Mode

You are helping organize writing projects. Use Sofia CLI tools rather than raw shell commands.

## MX Documentation

Read these files for guidance on how to help:
- `documentation/mx/README.md` - Overview of your role
- `documentation/mx/safety.md` - STOP/NEVER/VERIFY rules (critical)
- `documentation/mx/terminology.md` - Corpus, works, notes, reference definitions

## Sofia CLI Tools

| Tool | Purpose |
|------|---------|
| `sofia-work` | Manuscript management (init, ingest, surface, checkin, checkout) |
| `sofia-refresh` | Regenerate work-level notebook and manuscript sections |
| `sofia-wiki` | Entity extraction and continuity tracking |
| `sofia-dashboard` | Generate corpus/index.md dashboard |
| `sofia-tutorial` | Interactive tutorial for new users |

## Rules

1. **Use Sofia CLI tools** instead of raw shell commands for file organization
2. **Ask before any git commit or push** - never chain these operations
3. **Focus on writing organization**, not code development
4. **When in doubt**, run `cat documentation/mx/safety.md` to review safety rules

## Safety Summary

**STOP** - Ask before: git commit, git push, file deletion, moving files
**NEVER** - Chain commit && push, delete without listing files, assume backups exist
**VERIFY** - Check git status, confirm correct repository, explain consequences

## Your Purpose

Help the user organize their writing by:
- Processing incoming notes into works
- Managing chapter structure
- Tracking entities (characters, places, events)
- Maintaining continuity across the manuscript

Do not write code unless explicitly asked. Your primary role is writing organization.

## Custom Sections

Check `.sofia/sections/` in each work for prompt-based section definitions.
If present, read the prompt and generate content between the `<!-- sofia:marker -->` fences.
Always ask for user approval before writing generated sections.
"""
    
    // MARK: - Environment Locking
    
    func writeLockFile() {
        guard let env = activeEnvironment else { return }
        let sofiaDir = (env.path as NSString).appendingPathComponent(".sofia")
        let lockPath = (sofiaDir as NSString).appendingPathComponent("environment.lock")
        let fileManager = FileManager.default
        
        // Create .sofia directory if needed
        if !fileManager.fileExists(atPath: sofiaDir) {
            try? fileManager.createDirectory(atPath: sofiaDir, withIntermediateDirectories: true)
        }
        
        // Write lock file with environment info
        let lockContent = """
        # Sofia Environment Lock
        # This file indicates the AI assistant should only access files within this environment.
        
        locked_path: \(env.path)
        locked_at: \(ISO8601DateFormatter().string(from: Date()))
        environment_name: \(env.name)
        
        # AI assistants: Do NOT access files outside the locked_path above.
        """
        try? lockContent.write(toFile: lockPath, atomically: true, encoding: .utf8)
        
        // Also add restriction to .windsurfrules
        addLockRuleToWindsurfrules(env: env)
    }
    
    func removeLockFile() {
        guard let env = activeEnvironment else { return }
        let lockPath = (env.path as NSString).appendingPathComponent(".sofia/environment.lock")
        try? FileManager.default.removeItem(atPath: lockPath)
        
        // Remove lock rule from .windsurfrules
        removeLockRuleFromWindsurfrules(env: env)
    }
    
    private func addLockRuleToWindsurfrules(env: Environment) {
        let rulesPath = (env.path as NSString).appendingPathComponent(rulesFileName)
        let lockRule = """
        
        <!-- SOFIA ENVIRONMENT LOCK -->
        ## Environment Restriction
        
        **CRITICAL:** This environment is LOCKED. You must NEVER access files outside:
        `\(env.path)`
        
        Before ANY file operation, verify the path starts with the locked path above.
        <!-- END SOFIA ENVIRONMENT LOCK -->
        """
        
        var content = (try? String(contentsOfFile: rulesPath, encoding: .utf8)) ?? ""
        
        // Don't add if already present
        if content.contains("<!-- SOFIA ENVIRONMENT LOCK -->") { return }
        
        content += lockRule
        try? content.write(toFile: rulesPath, atomically: true, encoding: .utf8)
    }
    
    private func removeLockRuleFromWindsurfrules(env: Environment) {
        let rulesPath = (env.path as NSString).appendingPathComponent(rulesFileName)
        guard var content = try? String(contentsOfFile: rulesPath, encoding: .utf8) else { return }
        
        // Remove lock section
        if let startRange = content.range(of: "\n<!-- SOFIA ENVIRONMENT LOCK -->"),
           let endRange = content.range(of: "<!-- END SOFIA ENVIRONMENT LOCK -->\n") {
            content.removeSubrange(startRange.lowerBound..<endRange.upperBound)
        } else if let startRange = content.range(of: "<!-- SOFIA ENVIRONMENT LOCK -->"),
                  let endRange = content.range(of: "<!-- END SOFIA ENVIRONMENT LOCK -->") {
            content.removeSubrange(startRange.lowerBound...endRange.upperBound)
        }
        
        try? content.write(toFile: rulesPath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Writing Organization Mode
    
    func enableWritingMode() {
        guard let env = activeEnvironment else { return }
        let envPath = env.path
        let rulesPath = (envPath as NSString).appendingPathComponent(rulesFileName)
        let fileManager = FileManager.default
        
        // For VS Code, ensure .github directory exists
        if environmentEditor == "vscode" {
            let githubDir = (envPath as NSString).appendingPathComponent(".github")
            if !fileManager.fileExists(atPath: githubDir) {
                try? fileManager.createDirectory(atPath: githubDir, withIntermediateDirectories: true)
            }
        }
        
        // Use embedded template
        let sofiaRules = Self.writingRulesTemplate
        
        var existingContent = ""
        
        // Check if rules file exists and backup
        if fileManager.fileExists(atPath: rulesPath) {
            if let content = try? String(contentsOfFile: rulesPath, encoding: .utf8) {
                existingContent = content
                
                // Create dated backup
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let dateStr = dateFormatter.string(from: Date())
                let backupPath = rulesPath + ".backup-" + dateStr
                
                // Only backup if not already backed up today
                if !fileManager.fileExists(atPath: backupPath) {
                    try? fileManager.copyItem(atPath: rulesPath, toPath: backupPath)
                }
            }
        }
        
        // Build merged content with markers
        var mergedContent = "<!-- SOFIA WRITING MODE: ACTIVE -->\n"
        mergedContent += sofiaRules
        mergedContent += "\n<!-- END SOFIA WRITING MODE -->\n"
        
        if !existingContent.isEmpty && !existingContent.contains("<!-- SOFIA WRITING MODE") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: Date())
            mergedContent += "\n<!-- USER RULES (preserved from \(dateStr)) -->\n"
            mergedContent += existingContent
            mergedContent += "\n<!-- END USER RULES -->\n"
        } else if existingContent.contains("<!-- USER RULES") {
            // Already has user rules section, preserve it
            if let userRulesRange = existingContent.range(of: "<!-- USER RULES[\\s\\S]*<!-- END USER RULES -->", options: .regularExpression) {
                mergedContent += "\n" + String(existingContent[userRulesRange])
            }
        }
        
        try? mergedContent.write(toFile: rulesPath, atomically: true, encoding: .utf8)
    }
    
    func disableWritingMode() {
        guard let env = activeEnvironment else { return }
        let rulesPath = (env.path as NSString).appendingPathComponent(rulesFileName)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: rulesPath),
              let content = try? String(contentsOfFile: rulesPath, encoding: .utf8) else {
            return
        }
        
        // Extract user rules if present
        var restoredContent = ""
        
        if let userStart = content.range(of: "<!-- USER RULES"),
           let userEnd = content.range(of: "<!-- END USER RULES -->") {
            // Get content between markers
            let afterStart = content.index(after: content.range(of: " -->\n", range: userStart.upperBound..<content.endIndex)?.upperBound ?? userStart.upperBound)
            restoredContent = String(content[afterStart..<userEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if restoredContent.isEmpty {
            // No user rules to restore, just delete the file
            try? fileManager.removeItem(atPath: rulesPath)
        } else {
            // Write restored user rules
            try? restoredContent.write(toFile: rulesPath, atomically: true, encoding: .utf8)
        }
    }
    
    init() {
        loadEnvironments()
        startWatching()
    }
    
    func startWatching() {
        guard let env = activeEnvironment else { return }
        
        // Stop existing watcher
        fileWatcher?.stop()
        
        // Watch the works directory
        fileWatcher = FileWatcher(paths: [env.worksPath]) { [weak self] changedPath in
            guard let self = self else { return }
            
            // Only react to .md file changes
            if changedPath.hasSuffix(".md") {
                Task { @MainActor in
                    self.regenerateDashboard()
                    // Extract work name from changed path and refresh
                    if let workName = self.workName(from: changedPath) {
                        self.refreshWork(workName)
                    }
                }
            }
        }
        fileWatcher?.start()
        isWatching = true
    }
    
    func loadEnvironments() {
        let configURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SofiaMonitor")
            .appendingPathComponent("environments.json")
        
        guard let url = configURL, FileManager.default.fileExists(atPath: url.path) else {
            // Create default config if none exists
            createDefaultConfig()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(EnvironmentConfig.self, from: data)
            self.environments = config.environments
            self.isLocked = config.isLocked
            
            // If locked, set active to locked environment; otherwise most recently used
            if isLocked, let lockedId = config.lockedEnvironmentId {
                self.activeEnvironment = environments.first(where: { $0.id == lockedId })
            } else {
                self.activeEnvironment = environments.max(by: { $0.lastUsed < $1.lastUsed })
            }
        } catch {
            print("Error loading environments: \(error)")
        }
    }
    
    func createDefaultConfig() {
        // Scan for Sofia environments
        let discovered = scanForEnvironments()
        environments.append(contentsOf: discovered)
        
        if !environments.isEmpty {
            activeEnvironment = environments.first
            saveEnvironments()
        }
    }
    
    /// Recursively scan ~/Documents for directories containing corpus/ folder
    func scanForEnvironments(maxDepth: Int = 4) -> [Environment] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let documentsDir = homeDir.appendingPathComponent("Documents")
        var discovered: [Environment] = []
        let existingPaths = Set(environments.map { $0.path })
        
        func scan(directory: URL, depth: Int) {
            guard depth <= maxDepth else { return }
            
            let fileManager = FileManager.default
            let corpusPath = directory.appendingPathComponent("corpus")
            
            // Check if this directory has a corpus folder
            if fileManager.fileExists(atPath: corpusPath.path) {
                // Don't add if already in environments
                if !existingPaths.contains(directory.path) {
                    let env = Environment(
                        name: directory.lastPathComponent,
                        path: directory.path,
                        lastUsed: Date()
                    )
                    discovered.append(env)
                }
                return // Don't recurse into Sofia environments
            }
            
            // Recurse into subdirectories
            guard let contents = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return }
            
            for item in contents {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory),
                   isDirectory.boolValue {
                    scan(directory: item, depth: depth + 1)
                }
            }
        }
        
        scan(directory: documentsDir, depth: 1)
        return discovered
    }
    
    func saveEnvironments() {
        let configDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SofiaMonitor")
        
        guard let dir = configDir else { return }
        
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let config = EnvironmentConfig(
                environments: environments,
                defaultEditor: "windsurf",
                isLocked: isLocked,
                lockedEnvironmentId: isLocked ? activeEnvironment?.id : nil
            )
            let data = try JSONEncoder().encode(config)
            try data.write(to: dir.appendingPathComponent("environments.json"))
        } catch {
            print("Error saving environments: \(error)")
        }
    }
    
    func switchEnvironment(to env: Environment) {
        guard !isLocked else { return }  // Prevent switching when locked
        activeEnvironment = env
        
        // Update last used
        if let index = environments.firstIndex(where: { $0.id == env.id }) {
            environments[index].lastUsed = Date()
            saveEnvironments()
        }
        
        // Restart file watcher for new environment
        startWatching()
        
        // Regenerate dashboard for new environment
        regenerateDashboard()
    }
    
    func toggleLock() {
        isLocked.toggle()
        if isLocked {
            writeLockFile()
        } else {
            removeLockFile()
        }
        saveEnvironments()
    }
    
    func regenerateDashboard() {
        guard let envPath = activeEnvironment?.path else { return }
        
        let dashboardScript = URL(fileURLWithPath: envPath)
            .appendingPathComponent("scripts")
            .appendingPathComponent("sofia-dashboard")
        
        // If script exists, run it (creates/updates corpus/index.md)
        if FileManager.default.fileExists(atPath: dashboardScript.path) {
            let process = Process()
            process.executableURL = dashboardScript
            process.currentDirectoryURL = URL(fileURLWithPath: envPath)
            
            do {
                try process.run()
            } catch {
                print("Error running dashboard script: \(error)")
            }
        }
        
        // Ensure corpus/index.md exists (stub if script missing or corpus empty)
        ensureDashboardExists(envPath: envPath)
    }
    
    private func ensureDashboardExists(envPath: String) {
        let corpusDir = (envPath as NSString).appendingPathComponent("corpus")
        let dashboardFile = (corpusDir as NSString).appendingPathComponent("index.md")
        
        guard !FileManager.default.fileExists(atPath: dashboardFile) else { return }
        
        // Create corpus directory if needed
        if !FileManager.default.fileExists(atPath: corpusDir) {
            try? FileManager.default.createDirectory(atPath: corpusDir, withIntermediateDirectories: true)
        }
        
        let stub = """
# Author Dashboard

*No works yet. Use `sofia-work init` to create your first project.*

## Works

| Work | Words | Chapters | Phase | Last Edit |
|------|-------|----------|-------|-----------|

## Quick Links

- [Incoming Notes](incoming/) — Raw notes waiting to be processed

---

*Refresh with: `sofia-dashboard`*
"""
        try? stub.write(toFile: dashboardFile, atomically: true, encoding: .utf8)
    }
    
    /// Extract work name from a changed file path (e.g., .../corpus/works/my-novel/chapters/01.md → "my-novel")
    func workName(from changedPath: String) -> String? {
        guard let env = activeEnvironment else { return nil }
        let worksPrefix = (env.path as NSString).appendingPathComponent("corpus/works/")
        guard changedPath.hasPrefix(worksPrefix) else { return nil }
        let relative = String(changedPath.dropFirst(worksPrefix.count))
        return relative.components(separatedBy: "/").first
    }
    
    /// Run sofia-refresh for a specific work
    func refreshWork(_ workName: String) {
        guard let envPath = activeEnvironment?.path else { return }
        
        let refreshScript = URL(fileURLWithPath: envPath)
            .appendingPathComponent("scripts")
            .appendingPathComponent("sofia-refresh")
        
        guard FileManager.default.fileExists(atPath: refreshScript.path) else {
            return
        }
        
        let process = Process()
        process.executableURL = refreshScript
        process.arguments = [workName]
        process.currentDirectoryURL = URL(fileURLWithPath: envPath)
        
        do {
            try process.run()
        } catch {
            print("Error running refresh script: \(error)")
        }
    }
    
    func openInEditor(_ path: String? = nil) {
        let targetPath = path ?? activeEnvironment?.path ?? ""
        guard !targetPath.isEmpty else { return }
        
        // Determine which editor to use based on file extension
        let url = URL(fileURLWithPath: targetPath)
        let ext = url.pathExtension.lowercased()
        
        // Check if it's a directory (use environment editor)
        var isDirectory: ObjCBool = false
        let isDir = FileManager.default.fileExists(atPath: targetPath, isDirectory: &isDirectory) && isDirectory.boolValue
        
        let isDocumentFile = Self.documentExtensions.contains(ext)
        let editorId: String
        
        if isDir || Self.environmentExtensions.contains(ext) || ext.isEmpty {
            editorId = environmentEditor
        } else if isDocumentFile {
            editorId = documentEditor
        } else {
            // Default to environment editor for unknown types
            editorId = environmentEditor
        }
        
        // Use system default if selected
        if editorId == "system" {
            NSWorkspace.shared.open(url)
            return
        }
        
        // For document files, use NSWorkspace to open with the app
        if isDocumentFile {
            if let editor = Self.documentEditors.first(where: { $0.id == editorId }) {
                if FileManager.default.fileExists(atPath: editor.path) {
                    NSWorkspace.shared.open(
                        [url],
                        withApplicationAt: URL(fileURLWithPath: editor.path),
                        configuration: NSWorkspace.OpenConfiguration()
                    ) { _, error in
                        if let error = error {
                            print("Error opening with \(editor.name): \(error)")
                            NSWorkspace.shared.open(url)
                        }
                    }
                    return
                }
            }
            // Fallback to system default for documents
            NSWorkspace.shared.open(url)
            return
        }
        
        // For environment files/directories, use CLI tools
        if let editor = Self.environmentEditors.first(where: { $0.id == editorId }) {
            if FileManager.default.fileExists(atPath: editor.path) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: editor.path)
                process.arguments = [targetPath]
                try? process.run()
                return
            }
        }
        
        // Fallback: try any installed environment editor
        for editor in Self.environmentEditors where editor.id != "system" {
            if FileManager.default.fileExists(atPath: editor.path) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: editor.path)
                process.arguments = [targetPath]
                try? process.run()
                return
            }
        }
        
        // Last resort: system default
        NSWorkspace.shared.open(url)
    }
    
    func startTutorial() {
        guard let envPath = activeEnvironment?.path else { return }
        
        let tutorialScript = URL(fileURLWithPath: envPath)
            .appendingPathComponent("scripts")
            .appendingPathComponent("sofia-tutorial")
        
        guard FileManager.default.fileExists(atPath: tutorialScript.path) else {
            print("Tutorial script not found at: \(tutorialScript.path)")
            return
        }
        
        // Open terminal and run tutorial
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(envPath)' && ./scripts/sofia-tutorial"
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
