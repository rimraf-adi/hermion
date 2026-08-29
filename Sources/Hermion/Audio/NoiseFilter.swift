import Foundation
import AVFoundation
import Accelerate

public enum NoiseFilterMode: String, CaseIterable, Identifiable {
    case off = "Off (Raw Audio)"
    case light = "Light (Subtle Gate)"
    case medium = "Medium (Balanced - Recommended)"
    case aggressive = "Aggressive (Noisy Room / Cafe)"
    case voiceIsolation = "Voice Isolation (High Precision)"
    
    public var id: String { self.rawValue }
    
    public var thresholdGain: Float {
        switch self {
        case .off: return 0.0
        case .light: return 0.008
        case .medium: return 0.022
        case .aggressive: return 0.055
        case .voiceIsolation: return 0.085
        }
    }
    
    public var description: String {
        switch self {
        case .off: return "Passes raw uncompressed microphone input without noise reduction."
        case .light: return "Gentle noise floor suppression. Preserves delicate whisper details."
        case .medium: return "Optimal balance for everyday office/room noise, AC fans, and key clicks."
        case .aggressive: return "Cuts strong background chatter, ambient TV noise, and outdoor sounds."
        case .voiceIsolation: return "Strict voice-band isolation gate. Only lets active speech pass."
        }
    }
}

public class NoiseFilter: ObservableObject {
    public static let shared = NoiseFilter()
    
    @Published public var filterMode: NoiseFilterMode = .medium
    @Published public var noiseGateThresholdDB: Float = -42.0 // dB
    @Published public var highPassFilterEnabled: Bool = true
    @Published public var autoGainControl: Bool = true
    
    // Live metering for dry run visualizer
    @Published public var rawInputLevel: Float = 0.0
    @Published public var filteredOutputLevel: Float = 0.0
    @Published public var estimatedNoiseFloorDB: Float = -54.0
    @Published public var isVoiceDetected: Bool = false
    
    private var envelope: Float = 0.0
    private let attackAlpha: Float = 0.4
    private let releaseAlpha: Float = 0.05
    
    // High-pass filter state (Biquad DC blocking filter)
    private var hpPrevInput: Float = 0.0
    private var hpPrevOutput: Float = 0.0
    
    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: "Hermion_NoiseFilterMode"),
           let mode = NoiseFilterMode(rawValue: savedMode) {
            self.filterMode = mode
        }
        
        let savedGate = UserDefaults.standard.float(forKey: "Hermion_NoiseGateThreshold")
        if savedGate != 0.0 {
            self.noiseGateThresholdDB = savedGate
        }
        
        if UserDefaults.standard.object(forKey: "Hermion_HighPassEnabled") != nil {
            self.highPassFilterEnabled = UserDefaults.standard.bool(forKey: "Hermion_HighPassEnabled")
        }
    }
    
    public func setFilterMode(_ mode: NoiseFilterMode) {
        self.filterMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "Hermion_NoiseFilterMode")
    }
    
    public func setGateThresholdDB(_ threshold: Float) {
        self.noiseGateThresholdDB = threshold
        UserDefaults.standard.set(threshold, forKey: "Hermion_NoiseGateThreshold")
    }
    
    public func setHighPassEnabled(_ enabled: Bool) {
        self.highPassFilterEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "Hermion_HighPassEnabled")
    }
    
    /// Processes audio buffer in-place or returns filtered buffer
    public func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        
        // 1. Calculate Raw Input RMS
        var rawSum: Float = 0.0
        for i in 0..<frameCount {
            let s = channelData[i]
            rawSum += s * s
        }
        let rawRms = sqrt(rawSum / Float(frameCount))
        let rawDb = rawRms > 0.00001 ? 20.0 * log10(rawRms) : -96.0
        
        // 2. High Pass Rumble Filter (80Hz DC Blocker)
        if highPassFilterEnabled {
            let R: Float = 0.985 // ~80Hz cutoff at 44.1/48kHz
            for i in 0..<frameCount {
                let input = channelData[i]
                let output = input - hpPrevInput + R * hpPrevOutput
                hpPrevInput = input
                hpPrevOutput = output
                channelData[i] = output
            }
        }
        
        // 3. Spectral Noise Gate & Envelope Following
        let gateLinearThreshold = pow(10.0, (noiseGateThresholdDB + (filterMode == .off ? -100 : filterMode.thresholdGain * 50)) / 20.0)
        
        var isVoice = false
        if filterMode != .off {
            if rawRms > gateLinearThreshold {
                isVoice = true
                envelope = envelope * (1.0 - attackAlpha) + rawRms * attackAlpha
            } else {
                envelope = envelope * (1.0 - releaseAlpha)
            }
            
            // Attenuate background if envelope drops below threshold
            let gain: Float = envelope > (gateLinearThreshold * 0.7) ? 1.0 : max(0.0, envelope / gateLinearThreshold * 0.2)
            
            for i in 0..<frameCount {
                channelData[i] *= gain
            }
        } else {
            isVoice = rawRms > 0.005
        }
        
        // 4. Calculate Clean Filtered Output RMS
        var cleanSum: Float = 0.0
        for i in 0..<frameCount {
            let s = channelData[i]
            cleanSum += s * s
        }
        let cleanRms = sqrt(cleanSum / Float(frameCount))
        
        DispatchQueue.main.async {
            self.rawInputLevel = min(max(rawRms * 8.0, 0.0), 1.0)
            self.filteredOutputLevel = min(max(cleanRms * 8.0, 0.0), 1.0)
            self.estimatedNoiseFloorDB = rawDb
            self.isVoiceDetected = isVoice
        }
    }
}
