import SwiftUI
import AppKit

public struct WisprPillView: View {
    @ObservedObject var appState = AppState.shared
    @State private var dragOffset: CGSize = .zero
    
    private let numDots = 10
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // ── EXPANDED LIVE TRANSCRIPTION BUBBLE ───────────
            if appState.isListening && !appState.currentTranscript.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.purple)
                        .padding(.top, 2)
                    
                    Text(appState.currentTranscript)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: 440)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 14, y: 6)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // ── MAIN WISPR FLOW CAPSULE PILL ────────────────
            HStack(spacing: 8) {
                if appState.isListening {
                    // ── LISTENING STATE ─────────────────────────────
                    // Left: Cancel Button (Grey Circle with White X)
                    Button(action: {
                        appState.cancelListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.25, green: 0.25, blue: 0.28))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Center: Live Animated Equalizer Dots
                    HStack(spacing: 3.5) {
                        ForEach(0..<numDots, id: \.self) { index in
                            EqualizerBar(index: index, level: appState.audioLevel)
                        }
                    }
                    .frame(width: 70, height: 24)
                    
                    // Right: Stop/Insert Button (Coral Red Circle with Centered White Square)
                    Button(action: {
                        appState.stopListeningAndInject()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.94, green: 0.35, blue: 0.35))
                                .frame(width: 28, height: 28)
                                .shadow(color: Color(red: 0.94, green: 0.35, blue: 0.35).opacity(0.4), radius: 6)
                            
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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                } else {
                    // ── IDLE / READY STATE ──────────────────────────
                    // Left: Start Dictation Button (Purple/Violet Circle with Mic)
                    Button(action: {
                        appState.startListening()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.49, green: 0.23, blue: 0.93))
                                .frame(width: 28, height: 28)
                                .shadow(color: Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.4), radius: 6)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Center: Idle prompt / hotkey badge
                    HStack(spacing: 4) {
                        Text("F5")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text("Speak")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 76)
                    
                    // Right: History / Settings Button
                    Button(action: {
                        MenuBarManager.shared.showSettings()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.07))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.65), radius: 18, x: 0, y: 8)
            )
            .frame(width: 184, height: 44)
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
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: appState.isListening)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: appState.showInjectedToast)
        .animation(.easeInOut(duration: 0.15), value: appState.currentTranscript)
    }
}

struct EqualizerBar: View {
    let index: Int
    let level: Float
    
    var body: some View {
        let height: CGFloat = {
            let base: CGFloat = 3.5
            let wave = sin(Double(index) * 0.7 + Double(Date().timeIntervalSince1970 * 10)) * 0.5 + 0.5
            let amp = CGFloat(level) * 16.0
            return max(base, min(base + CGFloat(wave) * amp, 20.0))
        }()
        
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 3.2, height: height)
            .animation(.easeInOut(duration: 0.06), value: level)
    }
}
