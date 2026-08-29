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
        
        // Deep link directly into System Settings Accessibility pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Inject text into the frontmost application via Pasteboard + multi-strategy Cmd+V paste
    public static func injectViaPasteboard(_ text: String) {
        guard !text.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        
        // 1. Always copy transcription to system pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 2. Multi-Strategy Emulation of Cmd+V
        
        // Strategy A: CGEvent synthetic keypress
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 9 // ANSI V
        
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
        
        // Strategy B: AppleScript System Events fallback
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            let scriptSource = "tell application \"System Events\" to keystroke \"v\" using command down"
            if let script = NSAppleScript(source: scriptSource) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
            }
        }
    }
    
    /// Fallback: Inject via direct unicode keystrokes
    public static func injectViaKeystrokes(_ text: String) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for char in text.utf16 {
            var unichar = char
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }
            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unichar)
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unichar)
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            
            usleep(2000) // 2ms per character
        }
    }
}
