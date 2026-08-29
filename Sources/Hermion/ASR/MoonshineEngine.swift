import Foundation
import AVFoundation

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
    
    @Published public var isModelLoaded: Bool = true
    @Published public var isTranscribing: Bool = false
    @Published public var lastTranscript: String = ""
    
    private var audioBufferList: [Float] = []
    
    public init() {}
    
    public func startSession() {
        audioBufferList.removeAll()
        lastTranscript = ""
        isTranscribing = true
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
        
        // Ensure proper sentence capitalization
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
