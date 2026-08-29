import Foundation
import AppKit
import CoreGraphics

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
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
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
        
        // ── 1. HARDWARE-LEVEL CGEVENT TAP (Universal OS-Wide) ─────────
        setupEventTap()
        
        // ── 2. REDUNDANT NSEVENT MONITORS (Global & Local Fallback) ────
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isDown: true)
        }
        
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyEvent(event, isDown: false)
        }
        
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
        }
        
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event, isDown: true)
            return event
        }
        
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsEvent(event)
            return event
        }
    }
    
    private func setupEventTap() {
        let mask = (1 << CGEventType.keyDown.rawValue) |
                   (1 << CGEventType.keyUp.rawValue) |
                   (1 << CGEventType.flagsChanged.rawValue)
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                
                if let nsEvent = NSEvent(cgEvent: event) {
                    if type == .keyDown {
                        manager.handleKeyEvent(nsEvent, isDown: true)
                    } else if type == .keyUp {
                        manager.handleKeyEvent(nsEvent, isDown: false)
                    } else if type == .flagsChanged {
                        manager.handleFlagsEvent(nsEvent)
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        ) else {
            print("CGEvent.tapCreate unavailable, using NSEvent monitors.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
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
            matches = false
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
        
        // Handle Right Shift (KeyCode 60)
        if selectedHotkey == .rightShift {
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
    
    public func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
        }
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
