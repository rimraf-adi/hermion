import Foundation
import AVFoundation

public struct AudioInputDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let uniqueID: String
    
    public init(id: String, name: String, uniqueID: String) {
        self.id = id
        self.name = name
        self.uniqueID = uniqueID
    }
}

public class MicrophoneManager: ObservableObject {
    public static let shared = MicrophoneManager()
    
    @Published public var availableDevices: [AudioInputDevice] = []
    @Published public var selectedDeviceUniqueID: String = "default"
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "Hermion_SelectedMicrophoneID") {
            self.selectedDeviceUniqueID = saved
        }
        refreshDevices()
    }
    
    public func refreshDevices() {
        var devices: [AudioInputDevice] = [
            AudioInputDevice(id: "default", name: "System Default Microphone", uniqueID: "default")
        ]
        
        let audioDevices = AVCaptureDevice.devices(for: .audio)
        for dev in audioDevices {
            let item = AudioInputDevice(
                id: dev.uniqueID,
                name: dev.localizedName,
                uniqueID: dev.uniqueID
            )
            if !devices.contains(where: { $0.uniqueID == dev.uniqueID }) {
                devices.append(item)
            }
        }
        
        self.availableDevices = devices
    }
    
    public func selectDevice(uniqueID: String) {
        self.selectedDeviceUniqueID = uniqueID
        UserDefaults.standard.set(uniqueID, forKey: "Hermion_SelectedMicrophoneID")
    }
}
