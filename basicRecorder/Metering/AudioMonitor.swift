//
//  AudioMonitor.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/12/22.
//

import Foundation
import AVFoundation

class AudioMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    @Published public var soundSamples: [Float]
    @Published public var scaledVolume: Float = 0.0
    
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
            self.scaledVolume = self.scaleSample(sample: self.soundSamples[0])
        })
    }
    
    init(numberOfSamples: Int = 1) {
        self.numberOfSamples = numberOfSamples
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    fatalError("Microphone accessed is required for the use of this app.\nLike come on, you're recording.")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(false)
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func scaleSample(sample:Float) -> Float {
        let oldMax = 1.0
        let oldMin = -1.0
        let newMax = 100.0
        let newMin = 0.0
        
        let oldRange = oldMax - oldMin
        let newRange = newMax - newMin
        
        let newValue = (((Double(sample) - oldMin) * newRange) / oldRange) + newMin
        
        return Float(newValue)
    }
    
    func getChannelPower() -> Float {
        return scaleChannelPower(power: self.audioRecorder.peakPower(forChannel: 0))
    }
    
    
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}
