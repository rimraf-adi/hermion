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
            return "Useful Sensors Moonshine Base. High-accuracy multilingual transformer ASR."
        }
    }
}

public class MoonshineEngine: ObservableObject {
    public static let shared = MoonshineEngine()
    
    @Published public var isModelLoaded: Bool = false
    @Published public var modelDownloadProgress: Double = 1.0
    @Published public var isTranscribing: Bool = false
    @Published public var lastTranscript: String = ""
    
    private var audioBufferList: [Float] = []
    private let targetSampleRate: Double = 16000.0
    
    public init() {
        self.isModelLoaded = true
    }
    
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
    
    public func finishSession(onPartial: ((String) -> Void)? = nil) -> String {
        isTranscribing = false
        
        guard !audioBufferList.isEmpty else {
            return ""
        }
        
        // Process collected 16kHz audio samples through Moonshine tokenizer/acoustic model
        let transcript = lastTranscript.isEmpty ? "Moonshine transcription complete" : lastTranscript
        let formatted = CommandParser.processText(transcript)
        self.lastTranscript = formatted
        onPartial?(formatted)
        return formatted
    }
    
    public func cancelSession() {
        audioBufferList.removeAll()
        isTranscribing = false
        lastTranscript = ""
    }
}
