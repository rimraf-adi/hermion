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
    @Published public var selectedEngine: ASREngineType = .apple
    @Published public var showInjectedToast: Bool = false
    
    public let audioManager = AudioEngineManager()
    public let speechRecognizer = SpeechRecognizer()
    public let moonshineEngine = MoonshineEngine.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?
    
    public var onShowOverlay: (() -> Void)?
    public var onHideOverlay: (() -> Void)?
    
    private init() {
        self.historyItems = HistoryStorage.shared.loadHistory()
        
        if let savedEngine = UserDefaults.standard.string(forKey: "Hermion_ASREngine"),
           let engine = ASREngineType(rawValue: savedEngine) {
            self.selectedEngine = engine
        }
        
        // Link audio manager levels to state
        audioManager.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
        
        // Setup audio buffer forwarding
        audioManager.onBuffer = { [weak self] buffer, _ in
            guard let self = self else { return }
            self.speechRecognizer.appendAudioBuffer(buffer)
            if self.selectedEngine != .apple {
                self.moonshineEngine.appendAudioBuffer(buffer)
            }
        }
        
        setupHotkeys()
    }
    
    public func setEngine(_ engine: ASREngineType) {
        self.selectedEngine = engine
        UserDefaults.standard.set(engine.rawValue, forKey: "Hermion_ASREngine")
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
        
        HotkeyManager.shared.onCancel = { [weak self] in
            guard let self = self else { return }
            if self.isListening {
                self.cancelListening()
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
                self.beginAudioAndRecognition()
            }
        }
    }
    
    private func beginAudioAndRecognition() {
        do {
            self.currentTranscript = ""
            self.startTime = Date()
            self.isListening = true
            
            if selectedEngine != .apple {
                self.moonshineEngine.startSession()
            }
            
            try self.speechRecognizer.startRecognition { [weak self] partial in
                guard let self = self else { return }
                if self.selectedEngine == .apple {
                    self.currentTranscript = partial
                } else {
                    self.moonshineEngine.updateLivePartial(partial)
                    self.currentTranscript = self.moonshineEngine.lastTranscript
                }
            }
            
            try self.audioManager.start()
            self.onShowOverlay?()
        } catch {
            print("Failed to start listening: \(error)")
            self.isListening = false
        }
    }
    
    public func stopListeningAndInject() {
        guard isListening else { return }
        
        audioManager.stop()
        let raw = speechRecognizer.stopRecognition()
        
        let final: String
        if selectedEngine == .apple {
            final = raw
        } else {
            final = moonshineEngine.finishSession(withBaseTranscript: raw)
        }
        
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
            
            self.showInjectedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showInjectedToast = false
            }
        }
        
        self.currentTranscript = ""
    }
    
    public func cancelListening() {
        guard isListening else { return }
        
        audioManager.stop()
        speechRecognizer.cancelRecognition()
        if selectedEngine != .apple {
            moonshineEngine.cancelSession()
        }
        isListening = false
        currentTranscript = ""
        onHideOverlay?()
    }
}
