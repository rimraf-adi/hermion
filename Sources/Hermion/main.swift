import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Standard regular app with Dock icon and Menu Bar
        NSApp.setActivationPolicy(.regular)
        
        // Setup standard macOS Application Menu Bar (Cmd+Q, Cmd+W, Cmd+Z, Cmd+V, etc.)
        setupApplicationMenu()
        
        // Setup Local Keyboard Monitor for Cmd+Q
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
                NSApplication.shared.terminate(nil)
                return nil
            }
            return event
        }
        
        // Setup Main Dashboard Window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 680),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hermion Voice Keyboard"
        window.center()
        window.contentView = NSHostingView(rootView: MainDashboardView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.mainWindow = window
        
        // Setup floating Wispr Flow pill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
        
        // Setup macOS Menu Bar Status Item
        MenuBarManager.shared.setupMenuBar()
        
        // Pre-prompt permissions
        AppState.shared.audioManager.requestMicrophonePermission { _ in }
        AppState.shared.speechRecognizer.requestSpeechPermission { _ in }
        
        NSApp.activate(ignoringOtherApps: true)
        print("Hermion Voice Keyboard started successfully.")
    }
    
    private func setupApplicationMenu() {
        let mainMenu = NSMenu()
        
        // 1. App Menu (Hermion)
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        let aboutItem = NSMenuItem(title: "About Hermion", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(aboutItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let hideItem = NSMenuItem(title: "Hide Hermion", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideItem)
        
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        let showAllItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // QUIT ITEM WITH CMD+Q
        let quitItem = NSMenuItem(title: "Quit Hermion", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 2. File Menu (Close Window Cmd+W)
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(closeItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // 3. Edit Menu (Cut/Copy/Paste/Select All)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // 4. Window Menu (Minimize Cmd+M)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        let minimizeItem = NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(minimizeItem)
        let zoomItem = NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(zoomItem)
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func openSettingsFromMenu() {
        MenuBarManager.shared.showSettings()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Stay running in menu bar and floating pill when main window is closed
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
