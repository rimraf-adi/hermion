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
                    print("Speech recognition authorized")
                    completion(true)
                case .denied:
                    print("Speech recognition denied by user")
                    completion(false)
                case .restricted:
                    print("Speech recognition restricted on this device")
                    completion(false)
                case .notDetermined:
                    print("Speech recognition permission not determined")
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    public func startRecognition(onPartial: ((String) -> Void)? = nil) throws {
        stopRecognition()
        
        guard let recognizer = speechRecognizer else {
            throw NSError(domain: "HermionSpeech", code: 1, userInfo: [NSLocalizedDescriptionKey: "No recognizer for current locale."])
        }
        
        guard recognizer.isAvailable else {
            throw NSError(domain: "HermionSpeech", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is temporarily unavailable. Check Internet or Dictation settings."])
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Attempt on-device recognition if supported
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        } else {
            request.requiresOnDeviceRecognition = false
        }
        
        self.recognitionRequest = request
        self.isRecognizing = true
        self.partialText = ""
        self.errorDescription = nil
        
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let raw = result.bestTranscription.formattedString
                let formatted = CommandParser.processText(raw)
                DispatchQueue.main.async {
                    self.partialText = formatted
                    onPartial?(formatted)
                }
            }
            
            if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorDescription = error.localizedDescription
                }
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
        recognitionTask?.finish()
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
