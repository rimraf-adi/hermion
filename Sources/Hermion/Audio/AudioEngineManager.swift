import Foundation
import AVFoundation

public class AudioEngineManager: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var isRunning = false
    
    @Published public var audioLevel: Float = 0.0
    public var onBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    
    public init() {}
    
    public func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    public func start() throws {
        if isRunning {
            stop()
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // Calculate RMS audio level for UI equalizer
            if let channelData = buffer.floatChannelData?[0] {
                let frameLength = UInt(buffer.frameLength)
                var sum: Float = 0.0
                for i in 0..<frameLength {
                    let sample = channelData[Int(i)]
                    sum += sample * sample
                }
                let rms = sqrt(sum / Float(frameLength))
                let normalized = min(max(rms * 10.0, 0.0), 1.0)
                
                DispatchQueue.main.async {
                    self.audioLevel = normalized
                }
            }
            
            self.onBuffer?(buffer, time)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
    }
    
    public func stop() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.reset()
        isRunning = false
        DispatchQueue.main.async {
            self.audioLevel = 0.0
        }
    }
}
