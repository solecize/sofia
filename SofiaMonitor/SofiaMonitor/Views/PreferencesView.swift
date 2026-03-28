import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appState: AppState
    @State private var newEnvironmentPath: String = ""
    @State private var newEnvironmentName: String = ""
    @State private var showingAddSheet: Bool = false
    
    var body: some View {
        TabView {
            // Environments Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("Environments")
                    .font(.headline)
                
                // Lock toggle
                Toggle(isOn: Binding(
                    get: { appState.isLocked },
                    set: { _ in appState.toggleLock() }
                )) {
                    HStack {
                        Image(systemName: appState.isLocked ? "lock.fill" : "lock.open")
                            .foregroundColor(appState.isLocked ? .orange : .secondary)
                        VStack(alignment: .leading) {
                            Text("Lock to this repository")
                            Text("Prevents adding or switching environments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(appState.activeEnvironment == nil)
                
                if appState.isLocked {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Environment is locked. Unlock to make changes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                List {
                    ForEach(appState.environments) { env in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(env.name)
                                    .font(.body)
                                Text(env.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if env.id == appState.activeEnvironment?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contextMenu {
                            Button("Set as Active") {
                                appState.switchEnvironment(to: env)
                            }
                            Button("Remove", role: .destructive) {
                                removeEnvironment(env)
                            }
                            .disabled(appState.isLocked)
                        }
                    }
                }
                .frame(minHeight: 150)
                
                HStack {
                    Button("Add Environment...") {
                        showingAddSheet = true
                    }
                    .disabled(appState.isLocked)
                    
                    Spacer()
                    
                    Button("Scan for Environments") {
                        scanForEnvironments()
                    }
                    .disabled(appState.isLocked)
                }
            }
            .padding()
            .tabItem {
                Label("Environments", systemImage: "folder")
            }
            
            // Editor Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("Editor")
                    .font(.headline)
                
                Text("Select your preferred code editor:")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    EditorOption(name: "Windsurf", path: "/Applications/Windsurf.app")
                    EditorOption(name: "Cursor", path: "/Applications/Cursor.app")
                    EditorOption(name: "VS Code", path: "/Applications/Visual Studio Code.app")
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            // General Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("General")
                    .font(.headline)
                
                Toggle("Launch at Login", isOn: .constant(false))
                
                Toggle("Show Notifications", isOn: .constant(true))
                
                Toggle("Auto-commit on Save", isOn: .constant(true))
                
                Divider()
                
                Text("Commit Debounce")
                    .font(.subheadline)
                Text("Wait 2 seconds after last change before committing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Toggle(isOn: Binding(
                    get: { appState.tutorialMode },
                    set: { appState.tutorialMode = $0 }
                )) {
                    VStack(alignment: .leading) {
                        Text("Tutorial Mode")
                        Text("Show guided prompts when processing content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if appState.tutorialMode {
                    Button("Start Tutorial") {
                        appState.startTutorial()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
        }
        .frame(width: 450, height: 300)
        .sheet(isPresented: $showingAddSheet) {
            AddEnvironmentSheet(
                path: $newEnvironmentPath,
                name: $newEnvironmentName,
                onAdd: addEnvironment,
                onCancel: { showingAddSheet = false }
            )
        }
    }
    
    private func addEnvironment() {
        guard !newEnvironmentPath.isEmpty else { return }
        
        let name = newEnvironmentName.isEmpty ? 
            (newEnvironmentPath as NSString).lastPathComponent : 
            newEnvironmentName
        
        let env = Environment(
            name: name,
            path: newEnvironmentPath,
            lastUsed: Date()
        )
        
        appState.environments.append(env)
        appState.saveEnvironments()
        
        newEnvironmentPath = ""
        newEnvironmentName = ""
        showingAddSheet = false
    }
    
    private func removeEnvironment(_ env: Environment) {
        appState.environments.removeAll { $0.id == env.id }
        if appState.activeEnvironment?.id == env.id {
            appState.activeEnvironment = appState.environments.first
        }
        appState.saveEnvironments()
    }
    
    private func scanForEnvironments() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let documentsDir = homeDir.appendingPathComponent("Documents")
        
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: documentsDir,
            includingPropertiesForKeys: nil
        ) else { return }
        
        for url in contents {
            let corpusPath = url.appendingPathComponent("corpus")
            if FileManager.default.fileExists(atPath: corpusPath.path) {
                // Check if already added
                let path = url.path
                if !appState.environments.contains(where: { $0.path == path }) {
                    let env = Environment(
                        name: url.lastPathComponent,
                        path: path,
                        lastUsed: Date.distantPast
                    )
                    appState.environments.append(env)
                }
            }
        }
        
        appState.saveEnvironments()
    }
}

struct EditorOption: View {
    let name: String
    let path: String
    
    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    var body: some View {
        HStack {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isInstalled ? .green : .secondary)
            
            Text(name)
            
            Spacer()
            
            if isInstalled {
                Text("Installed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Not Found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddEnvironmentSheet: View {
    @Binding var path: String
    @Binding var name: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Environment")
                .font(.headline)
            
            HStack {
                TextField("Path", text: $path)
                    .textFieldStyle(.roundedBorder)
                
                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        path = url.path
                        if name.isEmpty {
                            name = url.lastPathComponent
                        }
                    }
                }
            }
            
            TextField("Name (optional)", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .disabled(path.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppState())
}
