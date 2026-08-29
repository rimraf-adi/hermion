import Foundation
import SwiftUI
import Combine

public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isListening: Bool = false
    @Published public var audioLevel: Float = 0.0
    @Published public var currentTranscript: String = ""
    @Published public var historyItems: [TranscriptionItem] = []
    @Published public var isPushToTalk: Bool = false
    @Published public var languageIdentifier: String = "en-US"
    
    public let audioManager = AudioEngineManager()
    public let speechRecognizer = SpeechRecognizer()
    
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?
    
    public var onShowOverlay: (() -> Void)?
    public var onHideOverlay: (() -> Void)?
    
    private init() {
        self.historyItems = HistoryStorage.shared.loadHistory()
        
        // Link audio manager levels to state
        audioManager.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
        
        // Setup audio buffer forwarding to speech recognizer
        audioManager.onBuffer = { [weak self] buffer, _ in
            self?.speechRecognizer.appendAudioBuffer(buffer)
        }
        
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        HotkeyManager.shared.onHotkeyDown = { [weak self] in
            guard let self = self else { return }
            if self.isPushToTalk {
                if !self.isListening {
                    self.startListening()
                }
            } else {
                // Toggle mode
                if self.isListening {
                    self.stopListeningAndInject()
                } else {
                    self.startListening()
                }
            }
        }
        
        HotkeyManager.shared.onHotkeyUp = { [weak self] in
            guard let self = self else { return }
            if self.isPushToTalk && self.isListening {
                self.stopListeningAndInject()
            }
        }
        
        HotkeyManager.shared.startMonitoring()
    }
    
    public func startListening() {
        guard !isListening else { return }
        
        audioManager.requestMicrophonePermission { [weak self] micGranted in
            guard let self = self, micGranted else { return }
            
            self.speechRecognizer.requestSpeechPermission { [weak self] speechGranted in
                guard let self = self, speechGranted else { return }
                
                do {
                    self.currentTranscript = ""
                    self.startTime = Date()
                    self.isListening = true
                    
                    try self.speechRecognizer.startRecognition { [weak self] partial in
                        self?.currentTranscript = partial
                    }
                    try self.audioManager.start()
                    
                    self.onShowOverlay?()
                } catch {
                    print("Failed to start listening: \(error)")
                    self.isListening = false
                }
            }
        }
    }
    
    public func stopListeningAndInject() {
        guard isListening else { return }
        
        audioManager.stop()
        let final = speechRecognizer.stopRecognition()
        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0.0
        
        isListening = false
        onHideOverlay?()
        
        let textToInject = final.trimmingCharacters(in: .whitespacesAndNewlines)
        if !textToInject.isEmpty {
            // Save to history
            let item = TranscriptionItem(text: textToInject, durationSeconds: duration)
            HistoryStorage.shared.saveItem(item)
            self.historyItems = HistoryStorage.shared.loadHistory()
            
            // Inject text into frontmost application
            TextInjector.injectViaPasteboard(textToInject)
        }
        
        self.currentTranscript = ""
    }
    
    public func cancelListening() {
        guard isListening else { return }
        
        audioManager.stop()
        speechRecognizer.cancelRecognition()
        isListening = false
        currentTranscript = ""
        onHideOverlay?()
    }
}
