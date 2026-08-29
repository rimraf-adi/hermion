import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var moonshineEngine = MoonshineEngine.shared
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        Form {
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
            
            // ── GENERAL & HOTKEYS ───────────────────────────────────
            Section(header: Text("General & Hotkeys").font(.headline)) {
                Toggle("Push-to-Talk Mode (Hold F5 to speak)", isOn: $appState.isPushToTalk)
                    .help("When enabled, hold F5 to speak and release to inject. When disabled, press F5 once to start, again to stop.")
                
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
        .frame(width: 440, height: 560)
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
