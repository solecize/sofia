import SwiftUI

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
        // Check for common Sofia locations
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let possiblePaths = [
            homeDir.appendingPathComponent("Documents/sofia"),
            homeDir.appendingPathComponent("Documents/writelab"),
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path.appendingPathComponent("corpus").path) {
                let env = Environment(
                    name: path.lastPathComponent,
                    path: path.path,
                    lastUsed: Date()
                )
                environments.append(env)
            }
        }
        
        if !environments.isEmpty {
            activeEnvironment = environments.first
            saveEnvironments()
        }
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
        saveEnvironments()
    }
    
    func regenerateDashboard() {
        guard let envPath = activeEnvironment?.path else { return }
        
        let dashboardScript = URL(fileURLWithPath: envPath)
            .appendingPathComponent("scripts")
            .appendingPathComponent("sofia-dashboard")
        
        guard FileManager.default.fileExists(atPath: dashboardScript.path) else {
            return
        }
        
        let process = Process()
        process.executableURL = dashboardScript
        process.currentDirectoryURL = URL(fileURLWithPath: envPath)
        
        do {
            try process.run()
        } catch {
            print("Error running dashboard script: \(error)")
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
