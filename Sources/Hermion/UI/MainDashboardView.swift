import SwiftUI
import AppKit

public struct MainDashboardView: View {
    @ObservedObject var appState = AppState.shared
    @State private var selectedTab = 0
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack(spacing: 16) {
                TabButton(title: "Voice", icon: "mic.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "History", icon: "clock.arrow.circlepath", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Settings", icon: "gearshape.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Tab Content
            Group {
                if selectedTab == 0 {
                    VoiceDashboardContent(isAccessibilityOk: $isAccessibilityOk)
                } else if selectedTab == 1 {
                    HistoryView()
                } else {
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 440, height: 600)
        .background(Color(red: 0.08, green: 0.08, blue: 0.11))
        .onAppear {
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white.opacity(0.12) : Color.clear)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct VoiceDashboardContent: View {
    @ObservedObject var appState = AppState.shared
    @Binding var isAccessibilityOk: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Info
            VStack(spacing: 4) {
                Text("Hermion")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Native macOS Voice Keyboard — Wispr Flow Overlay")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
            
            // Big Center Mic Pulse Button
            Button(action: {
                if appState.isListening {
                    appState.stopListeningAndInject()
                } else {
                    appState.startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(appState.isListening ? Color.red.opacity(0.2) : Color.purple.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appState.isListening ? (1.0 + CGFloat(appState.audioLevel) * 0.4) : 1.0)
                        .animation(.easeOut(duration: 0.08), value: appState.audioLevel)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: appState.isListening ? [Color.red, Color.orange] : [Color(red: 0.5, green: 0.2, blue: 0.95), Color(red: 0.35, green: 0.1, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: appState.isListening ? Color.red.opacity(0.6) : Color.purple.opacity(0.5), radius: 12)
                    
                    Image(systemName: appState.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Text(appState.isListening ? "Listening... Speak now (or press F5)" : "Press F5 or click Mic to dictate")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(appState.isListening ? .purple : .gray)
            
            // Live Waveform
            HStack(spacing: 4) {
                ForEach(0..<24, id: \.self) { i in
                    let h = max(4.0, min(CGFloat(appState.audioLevel) * 60.0 * sin(Double(i) * 0.4 + Double(Date().timeIntervalSince1970 * 8)) + 4.0, 36.0))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(appState.isListening ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 3.5, height: h)
                }
            }
            .frame(height: 40)
            
            // Live Transcript Box
            VStack(alignment: .leading, spacing: 6) {
                Text("Transcription")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                ScrollView {
                    Text(appState.currentTranscript.isEmpty ? (appState.isListening ? "Listening..." : "Your speech transcription will appear here in real-time...") : appState.currentTranscript)
                        .font(.system(size: 13))
                        .foregroundColor(appState.currentTranscript.isEmpty ? .gray : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 70)
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            
            // Floating Pill Overlay Controls
            HStack(spacing: 12) {
                Button(action: {
                    FloatingOverlayPanel.shared.showPanel()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pip.fill")
                        Text("Show Floating Pill")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                if !isAccessibilityOk {
                    Button(action: {
                        TextInjector.promptAccessibilityPermission()
                        isAccessibilityOk = TextInjector.isAccessibilityGranted()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Grant Accessibility")
                        }
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(.top, 10)
    }
}
