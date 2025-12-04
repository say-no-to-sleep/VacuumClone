import SwiftUI
import AppKit
import Combine

class AppManager: ObservableObject {
    @Published var runningApps: [AppItem] = []
    @Published var searchText: String = ""
    @AppStorage("safeList") private var safeListRaw: String = "com.apple.finder,com.apple.dock"
    
    var safeList: Set<String> {
        Set(safeListRaw.split(separator: ",").map { String($0) })
    }

    struct AppItem: Identifiable {
        let id: String
        let name: String
        let icon: NSImage
        let instance: NSRunningApplication
        var isSelected: Bool = false
    }
    
    init() {
        refreshApps()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshApps), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshApps), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }
    
    @objc func refreshApps() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular &&
                app.bundleIdentifier != Bundle.main.bundleIdentifier
            }
            .map { app in
                AppItem(
                    id: app.bundleIdentifier ?? UUID().uuidString,
                    name: app.localizedName ?? "Unknown",
                    icon: app.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)!,
                    instance: app,
                    isSelected: false
                )
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        DispatchQueue.main.async {
            self.runningApps = apps
        }
    }
    

    func playSuccessSound() {
        // Using Blow sound
        if let sound = NSSound(named: "Blow") {
            sound.volume = 0.5
            sound.play()
        }
    }
    
    func cleanSelected(onComplete: @escaping () -> Void) {
        let appsToClean = runningApps.filter { $0.isSelected }
        
        if appsToClean.isEmpty { return }

        for app in appsToClean {
            app.instance.terminate()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.refreshApps()
            self.playSuccessSound()
            onComplete()
        }
    }
    
    func toggleSafeList(bundleID: String) {
        var current = safeList
        if current.contains(bundleID) {
            current.remove(bundleID)
        } else {
            current.insert(bundleID)
        }
        safeListRaw = current.joined(separator: ",")
        objectWillChange.send()
    }
    
    
}
