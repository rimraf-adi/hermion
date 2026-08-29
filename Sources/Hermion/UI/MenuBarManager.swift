import AppKit
import SwiftUI

public class MenuBarManager {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    
    private init() {}
    
    public func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Hermion")
            button.image?.isTemplate = true
        }
        
        updateMenu()
    }
    
    public func updateMenu() {
        let menu = NSMenu()
        
        let isListening = AppState.shared.isListening
        let toggleTitle = isListening ? "Stop Dictation (F5)" : "Start Dictation (F5)"
        
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleListening), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let historyItem = NSMenuItem(title: "History...", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Hermion", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleListening() {
        if AppState.shared.isListening {
            AppState.shared.stopListeningAndInject()
        } else {
            AppState.shared.startListening()
        }
        updateMenu()
    }
    
    @objc public func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 380),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Hermion Settings"
            window.center()
            window.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc public func showHistory() {
        if historyWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Transcription History"
            window.center()
            window.contentView = NSHostingView(rootView: HistoryView())
            historyWindow = window
        }
        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
