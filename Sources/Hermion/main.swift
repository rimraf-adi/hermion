import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Standard regular app with Dock icon and Menu Bar
        NSApp.setActivationPolicy(.regular)
        
        // Setup Main Dashboard Window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hermion Voice Keyboard"
        window.center()
        window.contentView = NSHostingView(rootView: MainDashboardView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.mainWindow = window
        
        // Setup floating Wispr Flow pill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            FloatingOverlayPanel.shared.showPanel()
        }
        
        // Connect overlay panel events
        AppState.shared.onShowOverlay = {
            DispatchQueue.main.async {
                FloatingOverlayPanel.shared.showPanel()
                MenuBarManager.shared.updateMenu()
            }
        }
        
        AppState.shared.onHideOverlay = {
            DispatchQueue.main.async {
                MenuBarManager.shared.updateMenu()
            }
        }
        
        // Setup macOS Menu Bar
        MenuBarManager.shared.setupMenuBar()
        
        // Pre-prompt permissions
        AppState.shared.audioManager.requestMicrophonePermission { _ in }
        AppState.shared.speechRecognizer.requestSpeechPermission { _ in }
        
        NSApp.activate(ignoringOtherApps: true)
        print("Hermion Voice Keyboard started successfully.")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Stay running in menu bar and floating pill when main window is closed
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
