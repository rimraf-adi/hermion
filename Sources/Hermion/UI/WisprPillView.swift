import SwiftUI

public struct WisprPillView: View {
    @ObservedObject var appState = AppState.shared
    
    private let numDots = 10
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 8) {
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
            
            // Center: Live Animated Equalizer Dots / Waveform
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
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.05, green: 0.05, blue: 0.07))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 16, x: 0, y: 8)
        )
        .frame(width: 176, height: 42)
    }
}

struct EqualizerBar: View {
    let index: Int
    let level: Float
    
    var body: some View {
        let height: CGFloat = {
            let base: CGFloat = 3.5
            let wave = sin(Double(index) * 0.7 + Double(Date().timeIntervalSince1970 * 8)) * 0.5 + 0.5
            let amp = CGFloat(level) * 16.0
            return max(base, min(base + CGFloat(wave) * amp, 20.0))
        }()
        
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .frame(width: 3.2, height: height)
            .animation(.easeInOut(duration: 0.06), value: level)
    }
}
