import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var moonshineEngine = MoonshineEngine.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    @State private var isLaunchAtLogin = LaunchOnStartupManager.isLaunchAtLoginEnabled()
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        Form {
            // ── THEME & GRADIENT CUSTOMIZATION ───────────────────────
            Section(header: Text("Theme & Aesthetic Palette").font(.headline)) {
                VStack(spacing: 8) {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            themeManager.setTheme(theme)
                        }) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.gradient)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: theme.glowColor, radius: 4)
                                
                                Text(theme.rawValue)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primaryColor)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.currentTheme == theme ? Color.white.opacity(0.08) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // ── FLOATING PILL CUSTOMIZATION & SIZING ────────────────
            Section(header: Text("Floating Pill Appearance").font(.headline)) {
                HStack {
                    Text("Custom Label:")
                    TextField("Leave blank for minimal icon pill", text: $themeManager.customIdleText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: themeManager.customIdleText) { newText in
                            themeManager.setCustomIdleText(newText)
                        }
                }
                
                Toggle("Show Shortcut Key Badge on Pill", isOn: $themeManager.showHotkeyBadge)
                    .onChange(of: themeManager.showHotkeyBadge) { val in
                        themeManager.setShowHotkeyBadge(val)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Idle Pill Width:")
                        Spacer()
                        Text("\(Int(themeManager.pillIdleWidth)) px")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $themeManager.pillIdleWidth, in: 70...200, step: 2)
                        .onChange(of: themeManager.pillIdleWidth) { val in
                            themeManager.setPillIdleWidth(val)
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Recording Width:")
                        Spacer()
                        Text("\(Int(themeManager.pillRecordingWidth)) px")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $themeManager.pillRecordingWidth, in: 280...440, step: 10)
                        .onChange(of: themeManager.pillRecordingWidth) { val in
                            themeManager.setPillRecordingWidth(val)
                        }
                }
            }
            
            // ── SPEECH RECOGNITION ENGINE ────────────────────────────
            Section(header: Text("Speech Recognition Engine").font(.headline)) {
                Picker("Voice Engine", selection: $appState.selectedEngine) {
                    ForEach(ASREngineType.allCases) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .onChange(of: appState.selectedEngine) { newEngine in
                    appState.setEngine(newEngine)
                }
                
                Text(appState.selectedEngine.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // ── HARDWARE ACCELERATION & COMPUTE BACKEND ──────────────
            Section(header: Text("Hardware Acceleration & Backend").font(.headline)) {
                Picker("Compute Backend", selection: $moonshineEngine.computeBackend) {
                    ForEach(ComputeBackend.allCases) { backend in
                        HStack {
                            Image(systemName: backend.icon)
                            Text(backend.rawValue)
                        }
                        .tag(backend)
                    }
                }
                .onChange(of: moonshineEngine.computeBackend) { newBackend in
                    moonshineEngine.setBackend(newBackend)
                }
                
                Text(moonshineEngine.computeBackend.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Toggle("Auto-Fallback to CPU on High Load", isOn: $moonshineEngine.autoCPUFallback)
                    .onChange(of: moonshineEngine.autoCPUFallback) { enabled in
                        moonshineEngine.setAutoCPUFallback(enabled)
                    }
                
                HStack {
                    Image(systemName: "memorychip.fill")
                        .foregroundColor(.blue)
                    Text("Active Inference:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(moonshineEngine.activeInferenceDevice)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
            }
            
            // ── NOISE REDUCTION & AUDIO PROCESSING ──────────────────
            Section(header: Text("Noise Reduction & Audio Processing").font(.headline)) {
                NoiseFilterDryRunView()
            }
            
            // ── GENERAL & STARTUP ───────────────────────────────────
            Section(header: Text("General & Startup").font(.headline)) {
                Toggle("Launch Hermion on Startup", isOn: $isLaunchAtLogin)
                    .onChange(of: isLaunchAtLogin) { enabled in
                        LaunchOnStartupManager.setLaunchAtLogin(enabled: enabled)
                    }
                    .help("Automatically launch Hermion in background when logging into macOS.")
            }
            
            // ── KEYBOARD SHORTCUTS ──────────────────────────────────
            Section(header: Text("Keyboard Shortcuts").font(.headline)) {
                Picker("Activation Hotkey", selection: $hotkeyManager.selectedHotkey) {
                    ForEach(HotkeyOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .onChange(of: hotkeyManager.selectedHotkey) { newOption in
                    hotkeyManager.setHotkey(newOption)
                }
                
                Toggle("Push-to-Talk (Hold to speak, release to paste)", isOn: $appState.isPushToTalk)
                    .help("When enabled, hold the hotkey to speak and release to inject. When disabled, tap once to start, tap again or press Enter to paste.")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("⌨️ Quick Keyboard Actions:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Text("• Press ") + Text(hotkeyManager.selectedHotkey.badgeLabel).fontWeight(.bold) + Text(" to start dictating.")
                    Text("• Press ") + Text("Enter ↵").fontWeight(.bold) + Text(" while speaking to finish & paste immediately.")
                    Text("• Press ") + Text("Esc").fontWeight(.bold) + Text(" to cancel dictation.")
                }
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                
                Picker("Language", selection: $appState.languageIdentifier) {
                    Text("English (US)").tag("en-US")
                    Text("English (UK)").tag("en-GB")
                    Text("Spanish").tag("es-ES")
                    Text("French").tag("fr-FR")
                    Text("German").tag("de-DE")
                    Text("Japanese").tag("ja-JP")
                    Text("Chinese (Simplified)").tag("zh-CN")
                }
                .onChange(of: appState.languageIdentifier) { newLang in
                    appState.speechRecognizer.setLocale(Locale(identifier: newLang))
                }
            }
            
            // ── SYSTEM PERMISSIONS ──────────────────────────────────
            Section(header: Text("System Permissions").font(.headline)) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                    Text("Microphone Access")
                    Spacer()
                    Text("Configured")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "keyboard.fill")
                        .foregroundColor(.purple)
                    Text("Accessibility (Text Injection)")
                    Spacer()
                    if isAccessibilityOk {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Granted")
                        }
                        .foregroundColor(.green)
                        .font(.caption)
                    } else {
                        HStack(spacing: 8) {
                            Button("Grant Access") {
                                TextInjector.promptAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button("Relaunch App") {
                                relaunchApp()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                
                if !isAccessibilityOk {
                    Text("ℹ️ After toggling Hermion in System Settings, click 'Relaunch App' to activate permissions.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // ── ABOUT ───────────────────────────────────────────────
            Section(header: Text("About").font(.headline)) {
                HStack {
                    Text("Hermion Voice Keyboard")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("v1.0.0 Native")
                        .foregroundColor(.gray)
                }
                Text("Zero cloud calls • Apple MLX Metal & CPU backend • Wispr Flow floating overlay")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 600)
        .onAppear {
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
        .onReceive(timer) { _ in
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
    }
    
    private func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundleURL.path]
        try? process.run()
        NSApp.terminate(nil)
    }
}
