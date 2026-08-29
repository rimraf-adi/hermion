import SwiftUI
import AppKit

public struct MainDashboardView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Navigation Bar ─────────────────────────────────
            HStack(spacing: 12) {
                TabButton(title: "Voice", icon: "mic.fill", isSelected: selectedTab == 0, theme: themeManager.currentTheme) {
                    selectedTab = 0
                }
                TabButton(title: "History", icon: "clock.arrow.circlepath", isSelected: selectedTab == 1, theme: themeManager.currentTheme) {
                    selectedTab = 1
                }
                TabButton(title: "Settings", icon: "gearshape.fill", isSelected: selectedTab == 2, theme: themeManager.currentTheme) {
                    selectedTab = 2
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // ── Tab Content ─────────────────────────────────────────
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
        .frame(width: 460, height: 620)
        .background(
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                
                // Subtle ambient theme glow in background
                RadialGradient(
                    gradient: Gradient(colors: [themeManager.currentTheme.primaryColor.opacity(0.12), Color.clear]),
                    center: .top,
                    startRadius: 20,
                    endRadius: 400
                )
            }
        )
        .onAppear {
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
        .onReceive(timer) { _ in
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.primaryColor.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
                    )
                : nil
            )
        }
        .buttonStyle(.plain)
    }
}

struct VoiceDashboardContent: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @Binding var isAccessibilityOk: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Info & Theme Quick Selector
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hermion")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("System-wide Voice Keyboard")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Theme Swatches
                HStack(spacing: 6) {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            themeManager.setTheme(theme)
                        }) {
                            Circle()
                                .fill(theme.gradient)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: themeManager.currentTheme == theme ? 2 : 0)
                                )
                                .shadow(color: theme.glowColor, radius: themeManager.currentTheme == theme ? 4 : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
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
                        .fill(appState.isListening ? Color.red.opacity(0.18) : themeManager.currentTheme.primaryColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appState.isListening ? (1.0 + CGFloat(appState.audioLevel) * 0.45) : 1.0)
                        .animation(.easeOut(duration: 0.08), value: appState.audioLevel)
                    
                    Circle()
                        .fill(
                            appState.isListening ?
                            LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : themeManager.currentTheme.gradient
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: appState.isListening ? Color.red.opacity(0.6) : themeManager.currentTheme.glowColor, radius: 14)
                    
                    Image(systemName: appState.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Text(appState.isListening ? "Listening... Speak now (or press \(hotkeyManager.selectedHotkey.badgeLabel))" : "Press \(hotkeyManager.selectedHotkey.badgeLabel) or click Mic to dictate")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(appState.isListening ? themeManager.currentTheme.primaryColor : .gray)
            
            // 24-Band Precision Audio Waveform
            HStack(spacing: 3.5) {
                ForEach(0..<24, id: \.self) { i in
                    let h = max(4.0, min(CGFloat(appState.audioLevel) * 55.0 * sin(Double(i) * 0.4 + Double(Date().timeIntervalSince1970 * 8)) + 4.0, 36.0))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            appState.isListening ?
                            themeManager.currentTheme.gradient
                            : LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 3.5, height: h)
                }
            }
            .frame(height: 38)
            
            // Live Transcript Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Live Transcription Preview")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                    if appState.isListening {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                
                ScrollView {
                    Text(appState.currentTranscript.isEmpty ? (appState.isListening ? "Listening..." : "Your speech will stream here in real time as you speak...") : appState.currentTranscript)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(appState.currentTranscript.isEmpty ? .gray.opacity(0.7) : .white)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 72)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    FloatingOverlayPanel.shared.showPanel()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pip.fill")
                        Text("Show Floating Pill")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(themeManager.currentTheme.gradient)
                    .cornerRadius(8)
                    .shadow(color: themeManager.currentTheme.glowColor.opacity(0.4), radius: 6)
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
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(.top, 6)
    }
}
