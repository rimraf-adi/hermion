import Foundation
import AppKit

public enum HotkeyOption: String, CaseIterable, Identifiable {
    case f5 = "F5 (Function 5)"
    case optionSpace = "Option + Space (⌥ Space)"
    case controlSpace = "Control + Space (⌃ Space)"
    case rightOption = "Right Option Key (⌥)"
    
    public var id: String { self.rawValue }
    
    public var badgeLabel: String {
        switch self {
        case .f5: return "F5"
        case .optionSpace: return "⌥ Space"
        case .controlSpace: return "⌃ Space"
        case .rightOption: return "Right ⌥"
        }
    }
}

public class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    @Published public var selectedHotkey: HotkeyOption = .f5
    
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localKeyDownMonitor: Any?
    
    public var onHotkeyDown: (() -> Void)?
    public var onHotkeyUp: (() -> Void)?
    public var onQuickPaste: (() -> Void)?
    public var onCancel: (() -> Void)?
    
    private var isKeyDown = false
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "Hermion_SelectedHotkey"),
           let option = HotkeyOption(rawValue: saved) {
            self.selectedHotkey = option
        }
    }
    
    public func setHotkey(_ option: HotkeyOption) {
        self.selectedHotkey = option
        UserDefaults.standard.set(option.rawValue, forKey: "Hermion_SelectedHotkey")
        startMonitoring()
    }
    
    public func startMonitoring() {
        stopMonitoring()
        
        // 1. Global Monitor for Key Down (when outside Hermion)
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isDown: true)
        }
        
        // 2. Global Monitor for Key Up
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyEvent(event, isDown: false)
        }
        
        // 3. Flags monitor for modifier-only keys (Right Option)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
        }
        
        // 4. Local Monitor (when Hermion window has focus)
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.shouldInterceptLocalEvent(event) == true {
                return nil // consume event
            }
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent, isDown: Bool) {
        let keyCode = event.keyCode
        let flags = event.modifierFlags
        
        // Check Escape key (KeyCode 53) to cancel when listening
        if isDown && keyCode == 53 {
            DispatchQueue.main.async {
                self.onCancel?()
            }
            return
        }
        
        // Check Enter/Return key (KeyCode 36) to finish and paste when listening
        if isDown && keyCode == 36 && AppState.shared.isListening {
            DispatchQueue.main.async {
                self.onHotkeyDown?()
            }
            return
        }
        
        let matches: Bool
        switch selectedHotkey {
        case .f5:
            matches = (keyCode == 96) // F5
        case .optionSpace:
            matches = (keyCode == 49 && flags.contains(.option)) // Option+Space
        case .controlSpace:
            matches = (keyCode == 49 && flags.contains(.control)) // Control+Space
        case .rightOption:
            matches = false // Handled in flagsChanged
        }
        
        if matches {
            if isDown && !isKeyDown {
                isKeyDown = true
                DispatchQueue.main.async {
                    self.onHotkeyDown?()
                }
            } else if !isDown && isKeyDown {
                isKeyDown = false
                DispatchQueue.main.async {
                    self.onHotkeyUp?()
                }
            }
        }
    }
    
    private func handleFlagsEvent(_ event: NSEvent) {
        guard selectedHotkey == .rightOption else { return }
        
        // Right Option key code is typically 61
        let isOptionPressed = event.modifierFlags.contains(.option)
        if isOptionPressed && !isKeyDown {
            isKeyDown = true
            DispatchQueue.main.async {
                self.onHotkeyDown?()
            }
        } else if !isOptionPressed && isKeyDown {
            isKeyDown = false
            DispatchQueue.main.async {
                self.onHotkeyUp?()
            }
        }
    }
    
    private func shouldInterceptLocalEvent(_ event: NSEvent) -> Bool {
        if event.keyCode == 96 && selectedHotkey == .f5 {
            DispatchQueue.main.async {
                self.onHotkeyDown?()
            }
            return true
        }
        return false
    }
    
    public func stopMonitoring() {
        if let monitor = globalKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyDownMonitor = nil
        }
        if let monitor = globalKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyUpMonitor = nil
        }
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            globalFlagsMonitor = nil
        }
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        isKeyDown = false
    }
}
