import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appState: AppState
    @State private var newEnvironmentPath: String = ""
    @State private var newEnvironmentName: String = ""
    @State private var showingAddSheet: Bool = false
    @State private var showingWritingModeAlert: Bool = false
    
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
                Text("Editors")
                    .font(.headline)
                
                // Environment Editor Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment Editor")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("For directories, scripts, and code files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $appState.environmentEditor) {
                        ForEach(AppState.environmentEditors, id: \.id) { editor in
                            HStack {
                                if editor.id == "system" {
                                    Text("OS Default (\(AppState.osDefaultDirectoryApp))")
                                } else {
                                    Text(editor.name)
                                    if !FileManager.default.fileExists(atPath: editor.path) {
                                        Text("(not installed)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tag(editor.id)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Divider()
                
                // Document Editor Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document Editor")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("For markdown, text, and prose files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $appState.documentEditor) {
                        ForEach(AppState.documentEditors, id: \.id) { editor in
                            HStack {
                                if editor.id == "system" {
                                    Text("OS Default (\(AppState.osDefaultDocumentApp))")
                                } else {
                                    Text(editor.name)
                                    if !FileManager.default.fileExists(atPath: editor.path) {
                                        Text("(not installed)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tag(editor.id)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Editors", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            // General Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("General")
                    .font(.headline)
                
                Toggle("Launch at Login", isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.launchAtLogin = $0 }
                ))
                
                Toggle("Show Notifications", isOn: .constant(true))
                
                Toggle("Auto-commit on Save", isOn: .constant(true))
                
                Divider()
                
                Text("Commit Debounce")
                    .font(.subheadline)
                Text("Wait 2 seconds after last change before committing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tutorial")
                        .font(.subheadline)
                    Text("Learn Sofia with an interactive walkthrough")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Start Tutorial...") {
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
            
            // AI Assistant Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Assistant")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Writing Organization Mode", isOn: Binding(
                        get: { appState.writingModeEnabled },
                        set: { newValue in
                            if newValue {
                                showingWritingModeAlert = true
                            } else {
                                appState.writingModeEnabled = false
                                appState.disableWritingMode()
                            }
                        }
                    ))
                    
                    Text("Configures \(appState.rulesFileName) for writing organization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if appState.writingModeEnabled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Active in \(appState.activeEnvironment?.name ?? "environment")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                Text("When enabled, Sofia injects writing-focused rules into your AI assistant's configuration file. Your existing rules are preserved and can be restored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("AI Assistant", systemImage: "brain")
            }
            .alert("Enable Writing Organization Mode?", isPresented: $showingWritingModeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Enable") {
                    appState.writingModeEnabled = true
                    appState.enableWritingMode()
                }
            } message: {
                Text("This will modify \(appState.rulesFileName) in your active environment. Your existing rules will be preserved and can be restored by disabling this mode. A backup will be created.")
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
        // Use AppState's recursive scanner
        let discovered = appState.scanForEnvironments()
        appState.environments.append(contentsOf: discovered)
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

// NOTE: #Preview commented out for command-line swiftc compilation
// (PreviewsMacros plugin not available outside Xcode)
// #Preview {
//     PreferencesView()
//         .environmentObject(AppState())
// }
