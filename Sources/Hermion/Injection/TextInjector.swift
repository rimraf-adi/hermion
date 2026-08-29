import Foundation
import AppKit
import Carbon

public struct TextInjector {
    public static func isAccessibilityGranted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public static func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Reliable, universal text injection across all macOS apps
    public static func injectViaPasteboard(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 1. Copy text to system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(trimmed, forType: .string)
        
        // 2. Allow brief moment for pasteboard sync across target applications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let vKeyCode: CGKeyCode = 9 // ANSI V
            
            // Method A: Hardware CGEvent Cmd+V
            let source = CGEventSource(stateID: .hidSystemState)
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
                keyDown.flags = .maskCommand
                keyUp.flags = .maskCommand
                
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
            
            // Method B: AppleScript System Events fallback for Electron/Terminals/Sandboxed Apps
            let script = "tell application \"System Events\" to keystroke \"v\" using command down"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }
}
