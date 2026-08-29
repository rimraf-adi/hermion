import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory agent (no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Connect overlay panel to AppState events
        AppState.shared.onShowOverlay = {
            DispatchQueue.main.async {
                FloatingOverlayPanel.shared.showPanel()
                MenuBarManager.shared.updateMenu()
            }
        }
        
        AppState.shared.onHideOverlay = {
            DispatchQueue.main.async {
                FloatingOverlayPanel.shared.hidePanel()
                MenuBarManager.shared.updateMenu()
            }
        }
        
        // Initialize macOS Menu Bar
        MenuBarManager.shared.setupMenuBar()
        
        print("Hermion Native macOS Voice Keyboard active. Press F5 or click Menu Bar icon to speak.")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
