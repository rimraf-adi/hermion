import SwiftUI
import AppKit

public struct WisprPillView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    
    @State private var initialMouseLocation: NSPoint = .zero
    @State private var initialWindowLocation: NSPoint = .zero
    @State private var isDragging = false
    @State private var cursorBlink = false
    
    private let numDots = 8
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 8) {
            if appState.isListening {
                // ── 1. ACTIVE RECORDING MORPHED ISLAND ─────────────────────
                // Left: Cancel Button (✕)
                Button(action: {
                    appState.cancelListening()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .buttonStyle(.plain)
                
                // Sound-reactive Mini Equalizer
                HStack(spacing: 2.5) {
                    ForEach(0..<numDots, id: \.self) { index in
                        ThemedEqualizerBar(index: index, level: appState.audioLevel, theme: themeManager.currentTheme)
                    }
                }
                .frame(width: 38, height: 22)
                
                // Transparent Live Transcription Stream Area
                HStack(spacing: 3) {
                    if appState.currentTranscript.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(themeManager.currentTheme.primaryColor)
                                .frame(width: 6, height: 6)
                                .opacity(cursorBlink ? 1.0 : 0.3)
                            
                            Text("Listening...")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        Text(appState.currentTranscript)
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.head)
                        
                        Rectangle()
                            .fill(themeManager.currentTheme.primaryColor)
                            .frame(width: 1.8, height: 13)
                            .opacity(cursorBlink ? 1.0 : 0.0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                
                // Right: Stop & Insert Button (■)
                Button(action: {
                    appState.stopListeningAndInject()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.98, green: 0.38, blue: 0.38), Color(red: 0.88, green: 0.18, blue: 0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.red.opacity(0.5), radius: 6)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 8.5, height: 8.5)
                    }
                }
                .buttonStyle(.plain)
                
            } else if appState.showInjectedToast {
                // ── 2. TOAST CONFIRMATION STATE ────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Pasted (⌘V)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                
            } else {
                // ── 3. SLEEK IDLE CAPSULE ──────────────────────────────────
                // Left: Themed Glowing Mic
                Button(action: {
                    appState.startListening()
                }) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.gradient)
                            .frame(width: 28, height: 28)
                            .shadow(color: themeManager.currentTheme.glowColor, radius: 6)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Center: Hotkey Badge & Prompt
                HStack(spacing: 5) {
                    Text(hotkeyManager.selectedHotkey.badgeLabel)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                )
                        )
                    
                    Text("Speak")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(minWidth: 74)
                
                // Right: Settings Gear Button
                Button(action: {
                    MenuBarManager.shared.showSettings()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(
            width: appState.isListening ? 380 : 184,
            height: 42
        )
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.32),
                                    themeManager.currentTheme.primaryColor.opacity(appState.isListening ? 0.45 : 0.15),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: appState.isListening ? themeManager.currentTheme.glowColor.opacity(0.35) : Color.black.opacity(0.45),
                    radius: appState.isListening ? 20 : 14,
                    x: 0,
                    y: 6
                )
        )
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { _ in
                    guard let window = NSApp.windows.first(where: { $0 is FloatingOverlayPanel }) else { return }
                    let currentMouse = NSEvent.mouseLocation
                    if !isDragging {
                        isDragging = true
                        initialMouseLocation = currentMouse
                        initialWindowLocation = window.frame.origin
                    } else {
                        let dx = currentMouse.x - initialMouseLocation.x
                        let dy = currentMouse.y - initialMouseLocation.y
                        window.setFrameOrigin(NSPoint(x: initialWindowLocation.x + dx, y: initialWindowLocation.y + dy))
                    }
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorBlink.toggle()
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: appState.isListening)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: appState.showInjectedToast)
        .animation(.easeInOut(duration: 0.1), value: appState.currentTranscript)
    }
}

struct ThemedEqualizerBar: View {
    let index: Int
    let level: Float
    let theme: AppTheme
    
    var body: some View {
        let height: CGFloat = {
            let base: CGFloat = 3.0
            let wave = sin(Double(index) * 0.8 + Double(Date().timeIntervalSince1970 * 12)) * 0.5 + 0.5
            let amp = CGFloat(level) * 16.0
            return max(base, min(base + CGFloat(wave) * amp, 18.0))
        }()
        
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                LinearGradient(
                    colors: [Color.white, theme.primaryColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2.8, height: height)
            .animation(.easeInOut(duration: 0.06), value: level)
    }
}
