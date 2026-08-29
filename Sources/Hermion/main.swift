import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as floating accessory agent
        NSApp.setActivationPolicy(.accessory)
        
        // Show the Wispr Flow floating pill immediately on screen
        DispatchQueue.main.async {
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
        
        // Initialize macOS Menu Bar
        MenuBarManager.shared.setupMenuBar()
        
        // Pre-prompt permissions
        AppState.shared.audioManager.requestMicrophonePermission { _ in }
        AppState.shared.speechRecognizer.requestSpeechPermission { _ in }
        
        print("Hermion Wispr Flow Voice Keyboard active. Floating pill displayed on screen. Press F5 or click Mic to dictate.")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
