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
    }
    
    /// Inject text into the frontmost application via Pasteboard + Cmd+V with auto clipboard restoration
    public static func injectViaPasteboard(_ text: String) {
        guard !text.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        let previousString = pasteboard.string(forType: .string)
        
        // Always place the transcribed text on the pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Check if Accessibility is trusted
        if !isAccessibilityGranted() {
            print("⚠️ macOS Accessibility permission not granted. Prompting user...")
            promptAccessibilityPermission()
            // Keep text in clipboard so user can press Cmd+V manually
            return
        }
        
        // Emulate Cmd+V (Command + V)
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 9 // ANSI V
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            print("Failed to create CGEvent for Cmd+V")
            return
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        // Restore original clipboard contents after 300ms to allow target app to paste
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            if let prev = previousString {
                pasteboard.clearContents()
                pasteboard.setString(prev, forType: .string)
            }
        }
    }
    
    /// Fallback: Inject via direct unicode keystrokes
    public static func injectViaKeystrokes(_ text: String) {
        if !isAccessibilityGranted() {
            promptAccessibilityPermission()
            return
        }
        
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
