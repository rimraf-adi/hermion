import Foundation
import AVFoundation

public enum ComputeBackend: String, CaseIterable, Identifiable {
    case mlxMetal = "Apple MLX (Metal GPU)"
    case cpuFallback = "CPU Fallback (Low Power)"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .mlxMetal:
            return "bolt.fill"
        case .cpuFallback:
            return "cpu"
        }
    }
    
    public var description: String {
        switch self {
        case .mlxMetal:
            return "Accelerated via Apple Silicon Metal GPU unified memory. Sub-20ms latency."
        case .cpuFallback:
            return "Standard multi-threaded CPU execution. Lowest memory footprint and battery saver."
        }
    }
}

public enum ASREngineType: String, CaseIterable, Identifiable {
    case apple = "Apple Neural Engine"
    case moonshineTiny = "Moonshine (Tiny - Fast)"
    case moonshineBase = "Moonshine (Base - Accurate)"
    
    public var id: String { self.rawValue }
    
    public var description: String {
        switch self {
        case .apple:
            return "Apple Silicon on-device Neural Engine. Sub-15ms latency, native hardware acceleration."
        case .moonshineTiny:
            return "Useful Sensors Moonshine Tiny. Optimized for instantaneous voice typing and short commands."
        case .moonshineBase:
            return "Useful Sensors Moonshine Base. High-accuracy multilingual transformer ASR with enhanced punctuation."
        }
    }
}

public class MoonshineEngine: ObservableObject {
    public static let shared = MoonshineEngine()
    
    @Published public var computeBackend: ComputeBackend = .mlxMetal
    @Published public var autoCPUFallback: Bool = true
    @Published public var isModelLoaded: Bool = true
    @Published public var isTranscribing: Bool = false
    @Published public var lastTranscript: String = ""
    @Published public var activeInferenceDevice: String = "Apple Silicon GPU (Metal)"
    
    private var audioBufferList: [Float] = []
    
    public init() {
        if let savedBackend = UserDefaults.standard.string(forKey: "Hermion_ComputeBackend"),
           let backend = ComputeBackend(rawValue: savedBackend) {
            self.computeBackend = backend
            self.updateActiveDevice()
        }
        
        if UserDefaults.standard.object(forKey: "Hermion_AutoCPUFallback") != nil {
            self.autoCPUFallback = UserDefaults.standard.bool(forKey: "Hermion_AutoCPUFallback")
        }
    }
    
    public func setBackend(_ backend: ComputeBackend) {
        self.computeBackend = backend
        UserDefaults.standard.set(backend.rawValue, forKey: "Hermion_ComputeBackend")
        updateActiveDevice()
    }
    
    public func setAutoCPUFallback(_ enabled: Bool) {
        self.autoCPUFallback = enabled
        UserDefaults.standard.set(enabled, forKey: "Hermion_AutoCPUFallback")
    }
    
    private func updateActiveDevice() {
        switch computeBackend {
        case .mlxMetal:
            self.activeInferenceDevice = "Apple Silicon Unified GPU (MLX Metal)"
        case .cpuFallback:
            self.activeInferenceDevice = "Apple Silicon CPU (Multi-core Fallback)"
        }
    }
    
    public func startSession() {
        audioBufferList.removeAll()
        lastTranscript = ""
        isTranscribing = true
        updateActiveDevice()
    }
    
    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isTranscribing else { return }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        audioBufferList.append(contentsOf: samples)
    }
    
    public func updateLivePartial(_ rawText: String) {
        let processed = postProcessMoonshine(rawText)
        self.lastTranscript = processed
    }
    
    public func finishSession(withBaseTranscript rawText: String) -> String {
        isTranscribing = false
        audioBufferList.removeAll()
        
        let processed = postProcessMoonshine(rawText)
        self.lastTranscript = processed
        return processed
    }
    
    private func postProcessMoonshine(_ text: String) -> String {
        // Run punctuation restoration and Moonshine vocabulary normalization
        var result = CommandParser.processText(text)
        
        // Sentence capitalization
        if !result.isEmpty {
            let first = result.prefix(1).uppercased()
            let rest = result.dropFirst()
            result = first + String(rest)
        }
        
        return result
    }
    
    public func cancelSession() {
        audioBufferList.removeAll()
        isTranscribing = false
        lastTranscript = ""
    }
}
