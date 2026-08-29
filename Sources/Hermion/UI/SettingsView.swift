import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        Form {
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
                
                if appState.selectedEngine != .apple {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.purple)
                        Text("Moonshine ASR Engine active")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Spacer()
                        Text("100% On-Device")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    .padding(6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
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
            
            Section(header: Text("About").font(.headline)) {
                HStack {
                    Text("Hermion Voice Keyboard")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("v1.0.0 Native")
                        .foregroundColor(.gray)
                }
                Text("Zero cloud calls • On-device Apple Silicon neural speech & Moonshine ASR • Wispr Flow floating overlay")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
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
