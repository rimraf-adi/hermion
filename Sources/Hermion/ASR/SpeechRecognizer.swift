import Foundation
import Speech
import AVFoundation

public class SpeechRecognizer: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published public var partialText: String = ""
    @Published public var isRecognizing: Bool = false
    @Published public var errorDescription: String? = nil
    
    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    public func setLocale(_ locale: Locale) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    public func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    public func startRecognition(onPartial: ((String) -> Void)? = nil) throws {
        stopRecognition()
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "HermionSpeech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available."])
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Prefer on-device offline recognition when supported
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        self.recognitionRequest = request
        self.isRecognizing = true
        self.partialText = ""
        
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let formatted = CommandParser.processText(result.bestTranscription.formattedString)
                DispatchQueue.main.async {
                    self.partialText = formatted
                    onPartial?(formatted)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                // Recognition completed
            }
        }
    }
    
    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }
    
    @discardableResult
    public func stopRecognition() -> String {
        recognitionRequest?.endAudio()
        let finalResult = partialText
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
        return finalResult
    }
    
    public func cancelRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
        partialText = ""
    }
}
