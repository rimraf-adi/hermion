import AppKit
import SwiftUI

public class FloatingOverlayPanel: NSPanel {
    public static let shared = FloatingOverlayPanel()
    
    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 46),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        
        let hostingView = NSHostingView(rootView: WisprPillView())
        self.contentView = hostingView
        
        centerOnScreen()
    }
    
    public func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 90
            let y = screenRect.minY + 90 // Float gracefully near bottom
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    public func showPanel() {
        self.alphaValue = 0.0
        self.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            self.animator().alphaValue = 1.0
        }
    }
    
    public func hidePanel() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
}
