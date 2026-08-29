import SwiftUI
import AppKit

public struct WisprPillView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var dragOffset: CGSize = .zero
    
    private let numDots = 10
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // ── EXPANDED GLASSMORPHIC TRANSCRIPTION BUBBLE ───────────
            if appState.isListening && !appState.currentTranscript.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(themeManager.currentTheme.gradient)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                        .shadow(color: themeManager.currentTheme.glowColor, radius: 4)
                    
                    Text(appState.currentTranscript)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: 440)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.65))
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), themeManager.currentTheme.primaryColor.opacity(0.4), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
                )
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
            }
            
            // ── MAIN TRANSLUCENT WISPR FLOW CAPSULE PILL ────────────
            HStack(spacing: 8) {
                if appState.isListening {
                    // ── LISTENING STATE ─────────────────────────────
                    // Left: Cancel Button (Frosted Dark Circle with X)
                    Button(action: {
                        appState.cancelListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Center: Dynamic Equalizer with Theme Gradient
                    HStack(spacing: 3.5) {
                        ForEach(0..<numDots, id: \.self) { index in
                            ThemedEqualizerBar(index: index, level: appState.audioLevel, theme: themeManager.currentTheme)
                        }
                    }
                    .frame(width: 70, height: 26)
                    
                    // Right: Stop & Insert Button (Gradient Fill with Centered White Square)
                    Button(action: {
                        appState.stopListeningAndInject()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.96, green: 0.35, blue: 0.35), Color(red: 0.88, green: 0.20, blue: 0.30)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .shadow(color: Color(red: 0.96, green: 0.35, blue: 0.35).opacity(0.5), radius: 8)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: 9, height: 9)
                        }
                    }
                    .buttonStyle(.plain)
                    
                } else if appState.showInjectedToast {
                    // ── TOAST CONFIRMATION STATE ────────────────────
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Pasted (⌘V)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                } else {
                    // ── IDLE / READY STATE ──────────────────────────
                    // Left: Start Dictation Button (Themed Gradient Mic with Glow)
                    Button(action: {
                        appState.startListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeManager.currentTheme.gradient)
                                .frame(width: 30, height: 30)
                                .shadow(color: themeManager.currentTheme.glowColor, radius: 8)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12, weight: .semibold))
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
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(minWidth: 76)
                    
                    // Right: Settings Gear Button
                    Button(action: {
                        MenuBarManager.shared.showSettings()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.65))
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        themeManager.currentTheme.primaryColor.opacity(0.2),
                                        Color.white.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 8)
            )
            .frame(width: 190, height: 46)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    if let window = NSApp.windows.first(where: { $0 is FloatingOverlayPanel }) {
                        var frame = window.frame
                        frame.origin.x += value.translation.width - dragOffset.width
                        frame.origin.y -= value.translation.height - dragOffset.height
                        window.setFrame(frame, display: true)
                        dragOffset = value.translation
                    }
                }
                .onEnded { _ in
                    dragOffset = .zero
                }
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: appState.isListening)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: appState.showInjectedToast)
        .animation(.easeInOut(duration: 0.15), value: appState.currentTranscript)
    }
}

struct ThemedEqualizerBar: View {
    let index: Int
    let level: Float
    let theme: AppTheme
    
    var body: some View {
        let height: CGFloat = {
            let base: CGFloat = 3.5
            let wave = sin(Double(index) * 0.7 + Double(Date().timeIntervalSince1970 * 10)) * 0.5 + 0.5
            let amp = CGFloat(level) * 18.0
            return max(base, min(base + CGFloat(wave) * amp, 22.0))
        }()
        
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color.white, theme.primaryColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3.2, height: height)
            .animation(.easeInOut(duration: 0.06), value: level)
    }
}
