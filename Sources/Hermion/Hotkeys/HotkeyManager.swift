import Foundation
import AppKit

public enum HotkeyOption: String, CaseIterable, Identifiable {
    case rightShift = "Right Shift Key (⇧)"
    case doubleShift = "Double Tap Shift (⇧ ⇧)"
    case shiftSpace = "Shift + Space (⇧ Space)"
    case optionSpace = "Option + Space (⌥ Space)"
    case controlSpace = "Control + Space (⌃ Space)"
    case f5 = "F5 (Function 5)"
    
    public var id: String { self.rawValue }
    
    public var badgeLabel: String {
        switch self {
        case .rightShift: return "Right ⇧"
        case .doubleShift: return "⇧ ⇧"
        case .shiftSpace: return "⇧ Space"
        case .optionSpace: return "⌥ Space"
        case .controlSpace: return "⌃ Space"
        case .f5: return "F5"
        }
    }
}

public class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    @Published public var selectedHotkey: HotkeyOption = .rightShift
    
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localKeyDownMonitor: Any?
    private var localFlagsMonitor: Any?
    
    public var onHotkeyDown: (() -> Void)?
    public var onHotkeyUp: (() -> Void)?
    public var onQuickPaste: (() -> Void)?
    public var onCancel: (() -> Void)?
    
    private var isKeyDown = false
    private var lastShiftPressTime: Date = Date.distantPast
    
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
        
        // 1. Global Key Down
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isDown: true)
        }
        
        // 2. Global Key Up
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyEvent(event, isDown: false)
        }
        
        // 3. Global Flags Monitor (for Shift and modifier keys)
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
        }
        
        // 4. Local Key Down
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.shouldInterceptLocalEvent(event) == true {
                return nil
            }
            return event
        }
        
        // 5. Local Flags Monitor
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent, isDown: Bool) {
        let keyCode = event.keyCode
        let flags = event.modifierFlags
        
        // Escape (53) to cancel
        if isDown && keyCode == 53 && AppState.shared.isListening {
            DispatchQueue.main.async {
                self.onCancel?()
            }
            return
        }
        
        // Enter / Return (36) to finish & paste
        if isDown && keyCode == 36 && AppState.shared.isListening {
            DispatchQueue.main.async {
                self.onHotkeyDown?()
            }
            return
        }
        
        var matches = false
        switch selectedHotkey {
        case .shiftSpace:
            matches = (keyCode == 49 && flags.contains(.shift))
        case .optionSpace:
            matches = (keyCode == 49 && flags.contains(.option))
        case .controlSpace:
            matches = (keyCode == 49 && flags.contains(.control))
        case .f5:
            matches = (keyCode == 96)
        case .rightShift, .doubleShift:
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
        let keyCode = event.keyCode
        let isShiftActive = event.modifierFlags.contains(.shift)
        
        // Handle Right Shift (KeyCode 60 on macOS)
        if selectedHotkey == .rightShift {
            // Right Shift keyCode is 60 on standard Mac keyboards
            if keyCode == 60 || (isShiftActive && keyCode != 56) {
                if isShiftActive && !isKeyDown {
                    isKeyDown = true
                    DispatchQueue.main.async {
                        self.onHotkeyDown?()
                    }
                } else if !isShiftActive && isKeyDown {
                    isKeyDown = false
                    DispatchQueue.main.async {
                        self.onHotkeyUp?()
                    }
                }
            }
        }
        
        // Handle Double Tap Shift
        if selectedHotkey == .doubleShift {
            if isShiftActive {
                let now = Date()
                let interval = now.timeIntervalSince(lastShiftPressTime)
                if interval > 0.05 && interval < 0.40 {
                    // Double tap detected!
                    lastShiftPressTime = Date.distantPast
                    DispatchQueue.main.async {
                        self.onHotkeyDown?()
                    }
                } else {
                    lastShiftPressTime = now
                }
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
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        isKeyDown = false
    }
}
