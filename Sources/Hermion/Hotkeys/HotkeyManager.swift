import Foundation
import AppKit

public class HotkeyManager {
    public static let shared = HotkeyManager()
    
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var globalFlagsMonitor: Any?
    
    public var onHotkeyDown: (() -> Void)?
    public var onHotkeyUp: (() -> Void)?
    
    private var isKeyDown = false
    private let targetKeyCode: UInt16 = 96 // F5 key code on macOS
    
    private init() {}
    
    public func startMonitoring() {
        stopMonitoring()
        
        // Global monitor for keyDown events when other apps are active
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if event.keyCode == self.targetKeyCode && !self.isKeyDown {
                self.isKeyDown = true
                DispatchQueue.main.async {
                    self.onHotkeyDown?()
                }
            }
        }
        
        // Global monitor for keyUp events
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            guard let self = self else { return }
            if event.keyCode == self.targetKeyCode && self.isKeyDown {
                self.isKeyDown = false
                DispatchQueue.main.async {
                    self.onHotkeyUp?()
                }
            }
        }
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
        isKeyDown = false
    }
}
