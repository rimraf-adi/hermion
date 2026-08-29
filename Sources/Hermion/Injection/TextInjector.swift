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
        
        // Put transcription onto pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Emulate Cmd+V (Command + V)
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 9 // ANSI V
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        // Restore original clipboard contents after short delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            if let prev = previousString {
                pasteboard.clearContents()
                pasteboard.setString(prev, forType: .string)
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
            
            usleep(1500) // 1.5ms per character
        }
    }
}
