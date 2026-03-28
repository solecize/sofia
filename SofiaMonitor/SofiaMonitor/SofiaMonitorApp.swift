import SwiftUI

@main
struct SofiaMonitorApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            PreferencesView()
                .environmentObject(appState)
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
    
    private var fileWatcher: FileWatcher?
    private var gitService: GitService?
    
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
    
    init() {
        loadEnvironments()
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
    }
    
    func toggleLock() {
        isLocked.toggle()
        saveEnvironments()
    }
    
    func openInEditor(_ path: String? = nil) {
        let targetPath = path ?? activeEnvironment?.path ?? ""
        guard !targetPath.isEmpty else { return }
        
        // Try Windsurf first, then Cursor, then VS Code
        let editors = [
            "/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf",
            "/Applications/Cursor.app/Contents/Resources/app/bin/cursor",
            "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        ]
        
        for editor in editors {
            if FileManager.default.fileExists(atPath: editor) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: editor)
                process.arguments = [targetPath]
                try? process.run()
                return
            }
        }
    }
}
