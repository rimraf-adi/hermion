import SwiftUI
import AppKit

public struct NoiseFilterDryRunView: View {
    @ObservedObject var noiseFilter = NoiseFilter.shared
    @ObservedObject var appState = AppState.shared
    @ObservedObject var themeManager = ThemeManager.shared
    
    @State private var isDryRunTesting = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("Noise Reduction & Dry-Run")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Mic Test Button
                Button(action: {
                    toggleDryRun()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isDryRunTesting ? "stop.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(isDryRunTesting ? "Stop Mic Test" : "Test Mic Dry-Run")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(isDryRunTesting ? .red : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(isDryRunTesting ? Color.red.opacity(0.18) : themeManager.currentTheme.primaryColor.opacity(0.2))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isDryRunTesting ? Color.red.opacity(0.4) : themeManager.currentTheme.primaryColor.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Dual Live Meters (Raw Input vs Cleaned Filtered Output)
            VStack(spacing: 8) {
                // Raw Input Meter
                HStack(spacing: 8) {
                    Text("Raw Input")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 72, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.yellow, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(noiseFilter.rawInputLevel)))
                        }
                    }
                    .frame(height: 8)
                }
                
                // Cleaned Filtered Voice Output Meter
                HStack(spacing: 8) {
                    Text("Clean Voice")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(noiseFilter.isVoiceDetected ? .green : .gray)
                        .frame(width: 72, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, themeManager.currentTheme.primaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * CGFloat(noiseFilter.filteredOutputLevel)))
                                .shadow(color: noiseFilter.isVoiceDetected ? Color.green.opacity(0.4) : Color.clear, radius: 4)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.25))
            .cornerRadius(8)
            
            // Noise Filter Mode Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Suppression Profile:")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Picker("", selection: $noiseFilter.filterMode) {
                    ForEach(NoiseFilterMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: noiseFilter.filterMode) { newMode in
                    noiseFilter.setFilterMode(newMode)
                }
                
                Text(noiseFilter.filterMode.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            // Noise Gate Threshold Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Noise Gate Threshold:")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(noiseFilter.noiseGateThresholdDB)) dB")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                Slider(value: $noiseFilter.noiseGateThresholdDB, in: -60...(-20), step: 1)
                    .onChange(of: noiseFilter.noiseGateThresholdDB) { val in
                        noiseFilter.setGateThresholdDB(val)
                    }
            }
            
            // 80Hz High-Pass Rumble Filter
            Toggle("80Hz Low-End Rumble Filter (Cuts Mic Pops & AC Hum)", isOn: $noiseFilter.highPassFilterEnabled)
                .font(.system(size: 11.5, design: .rounded))
                .onChange(of: noiseFilter.highPassFilterEnabled) { enabled in
                    noiseFilter.setHighPassEnabled(enabled)
                }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func toggleDryRun() {
        if isDryRunTesting {
            isDryRunTesting = false
            appState.audioManager.stop()
        } else {
            isDryRunTesting = true
            appState.audioManager.requestMicrophonePermission { granted in
                guard granted else { return }
                try? appState.audioManager.start()
            }
        }
    }
}
