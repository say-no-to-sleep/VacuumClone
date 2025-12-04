import SwiftUI
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var manager: AppManager
    @State private var showSettings = false
    @State private var showSuccess = false
    
    // "KeYbOaRd fiRst" "focus management"
    @FocusState private var isSearchFocused: Bool
    
    var filteredApps: [Binding<AppManager.AppItem>] {
        $manager.runningApps.filter { app in
            manager.searchText.isEmpty || app.wrappedValue.name.localizedCaseInsensitiveContains(manager.searchText)
        }
    }
    
    var selectedCount: Int {
        manager.runningApps.filter { $0.isSelected }.count
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                HStack {
                    Text("Vacuum Clone")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    
                    // Settings
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showSettings) {
                        SettingsView()
                            .environmentObject(manager)
                            .frame(width: 250, height: 300)
                    }
                    
                    Spacer().frame(width: 15)
                    
                    // quit
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .fontWeight(.bold)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // search CMD+F
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search apps...", text: $manager.searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                }
                .padding(8)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if filteredApps.isEmpty {
                            Text("No apps found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                        } else {
                            ForEach(filteredApps) { $app in
                                if !manager.safeList.contains(app.id) {
                                    AppRow(app: $app)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onTapGesture { isSearchFocused = false }
                
                VStack {
                    Divider()
                    HStack {
                        Toggle("Select All", isOn: Binding(
                            get: {
                                 !manager.runningApps.isEmpty && manager.runningApps.allSatisfy { $0.isSelected || manager.safeList.contains($0.id) }
                            },
                            set: { newVal in
                                for i in 0..<manager.runningApps.count {
                                    if !manager.safeList.contains(manager.runningApps[i].id) {
                                        manager.runningApps[i].isSelected = newVal
                                    }
                                }
                            }
                        ))
                        .font(.caption)
                        .toggleStyle(.checkbox)
                        
                        Spacer()
                        
                        Text("\(selectedCount) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Button(action: {
                        triggerClean()
                    }) {
                        HStack {
                            Image(systemName: "wind")
                            Text("Clean \(selectedCount) Apps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .keyboardShortcut(.defaultAction) // Enter Key
                }
                .background(.ultraThinMaterial)
            }
            .blur(radius: showSuccess ? 5 : 0)
            
            // THE SUCCESS ANIMATION LAYER
            if showSuccess {
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green.gradient)
                        .shadow(radius: 10)
                    
                    Text("Mmm! Cleaned!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        // GLOBAL KEYBOARD SHORTCUTS
        .background {
            // CMD+A
            Button("") {
                let allSelected = manager.runningApps.allSatisfy { $0.isSelected || manager.safeList.contains($0.id) }
                for i in 0..<manager.runningApps.count {
                    if !manager.safeList.contains(manager.runningApps[i].id) {
                        manager.runningApps[i].isSelected = !allSelected
                    }
                }
            }
            .keyboardShortcut("a", modifiers: .command)
            .hidden()
            
            // CMD+F
            Button("") {
                isSearchFocused = true
            }
            .keyboardShortcut("f", modifiers: .command)
            .hidden()
        }
    }
    
    // helper
    func triggerClean() {
        manager.cleanSelected {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSuccess = false
                }
            }
        }
    }
}

// Row View
struct AppRow: View {
    @Binding var app: AppManager.AppItem
    
    var body: some View {
        HStack {
            Toggle("", isOn: $app.isSelected)
                .labelsHidden()
                .toggleStyle(.checkbox)
                .allowsHitTesting(false)
            
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 24, height: 24)
            
            Text(app.name)
                .font(.system(size: 14))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(8)
        .background(app.isSelected ? Color.blue.opacity(0.1) : Color.primary.opacity(0.03))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            app.isSelected.toggle()
        }
    }
}

// Settings View
struct SettingsView: View {
    @EnvironmentObject var manager: AppManager
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.headline)
                .padding()
            
            Divider()
            
            // Launch at Login
            Toggle("Start at Login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    launchAtLogin = newValue
                    if newValue {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }
            ))
            .toggleStyle(.switch)
            .padding()
            
            Divider()
            
            Text("Safe List")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 5)
                
            // Safe List
            List {
                ForEach(manager.runningApps) { app in
                    HStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(app.name)
                        Spacer()
                        Button(action: { manager.toggleSafeList(bundleID: app.id) }) {
                            Image(systemName: manager.safeList.contains(app.id) ? "lock.fill" : "lock.open")
                                .foregroundColor(manager.safeList.contains(app.id) ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            Text("Locked apps will never be selected.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(10)
        }
    }
}
