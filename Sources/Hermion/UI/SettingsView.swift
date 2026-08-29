import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var isAccessibilityOk = TextInjector.isAccessibilityGranted()
    
    public init() {}
    
    public var body: some View {
        Form {
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
                        Text("Granted")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Button("Grant Access") {
                            TextInjector.promptAccessibilityPermission()
                            isAccessibilityOk = TextInjector.isAccessibilityGranted()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
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
                Text("Zero cloud calls • On-device Apple Silicon neural speech recognition • Wispr Flow floating overlay")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 380)
        .onAppear {
            isAccessibilityOk = TextInjector.isAccessibilityGranted()
        }
    }
}
