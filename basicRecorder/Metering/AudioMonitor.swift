

import Foundation
import AVFoundation

class AudioMonitor: ObservableObject {
    var audioRecorder: AVAudioRecorder
    var timer: Timer?
    
    var currentSample: Int
    let numberOfSamples: Int
    
    @Published var soundSamples: [Float]
    
    deinit {    // fuck you why are you only happy up here >:(
        timer?.invalidate()
        audioRecorder.stop()
    }
    
    init (numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    print("Microphone permission required...")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        func startMonitoring() {
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
                self.audioRecorder.updateMeters()
                self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
                self.currentSample = (self.currentSample + 1) % self.numberOfSamples
            })
        }
        
        
    }
}
