import SwiftUI
import AppKit

@main
struct VacuumCloneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wind", accessibilityDescription: "Vacuum")
            button.action = #selector(togglePopover)
        }
        
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.animates = true
        
        let appManager = AppManager()
        
        popover.contentViewController = NSHostingController(rootView:
            ContentView()
                .environmentObject(appManager)
                .frame(width: 320, height: 450)
        )
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}
