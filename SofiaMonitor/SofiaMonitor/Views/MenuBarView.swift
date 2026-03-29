import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var works: [Work] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(appState.statusColor)
                    .font(.caption)
                Text("Sofia Monitor")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Environments section
            HStack {
                Text("Environment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if appState.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            if appState.isLocked {
                // When locked, only show active environment
                if let env = appState.activeEnvironment {
                    EnvironmentRow(
                        environment: env,
                        isActive: true,
                        isLocked: true
                    )
                }
            } else {
                // When unlocked, show all environments
                ForEach(appState.environments) { env in
                    EnvironmentRow(
                        environment: env,
                        isActive: env.id == appState.activeEnvironment?.id,
                        isLocked: false
                    )
                    .onTapGesture {
                        appState.switchEnvironment(to: env)
                        refreshWorks()
                    }
                }
                
                if appState.environments.isEmpty {
                    Text("No environments configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Works section
            if let env = appState.activeEnvironment {
                Text("Works (\(env.name))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                
                ForEach(works) { work in
                    WorkRow(work: work)
                }
                
                if works.isEmpty {
                    Text("No works found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Pending changes
            if appState.pendingChanges > 0 {
                HStack {
                    Image(systemName: "doc.badge.clock")
                    Text("\(appState.pendingChanges) changes pending review")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                
                Button("Review Changes...") {
                    // TODO: Open changelog view
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Actions
            Menu("Open in \(appState.environmentEditorName)") {
                ForEach(appState.environments) { env in
                    Button(env.name + "/") {
                        appState.openInEditor(env.path)
                    }
                }
                
                Divider()
                
                if let env = appState.activeEnvironment {
                    ForEach(works.prefix(3)) { work in
                        Button("\(env.name)/corpus/works/\(work.name)") {
                            appState.openInEditor(work.path)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Button("Open Dashboard") {
                if let env = appState.activeEnvironment {
                    appState.openInEditor(env.dashboardPath)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Button("Start Tutorial...") {
                appState.startTutorial()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 4)
            
            SettingsLink {
                Text("Preferences...")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
        .onAppear {
            refreshWorks()
        }
    }
    
    private func refreshWorks() {
        if let env = appState.activeEnvironment {
            works = StatsService.getWorks(for: env)
        }
    }
}

struct EnvironmentRow: View {
    let environment: Environment
    let isActive: Bool
    var isLocked: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .foregroundColor(isActive ? .green : .secondary)
                .font(.caption2)
            
            Text(environment.name)
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text("(locked)")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if isActive {
                Text("(active)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct WorkRow: View {
    let work: Work
    
    var body: some View {
        HStack {
            Image(systemName: work.hasRecentChanges ? "circle.fill" : "checkmark")
                .foregroundColor(work.hasRecentChanges ? .yellow : .green)
                .font(.caption2)
            
            Text(work.name)
            
            Spacer()
            
            Text(work.lastEditDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// NOTE: #Preview commented out for command-line swiftc compilation
// (PreviewsMacros plugin not available outside Xcode)
// #Preview {
//     MenuBarView()
//         .environmentObject(AppState())
// }
