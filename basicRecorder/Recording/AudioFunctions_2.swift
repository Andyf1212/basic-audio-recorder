

import Foundation
import SwiftUI
import Combine
import AVFoundation

class AudioRecorder: NSObject,ObservableObject {
    
    override init() {
        super.init()
        fetchRecordings()
    }
    
    let objectWillChange = PassthroughSubject<AudioRecorder,Never>()
    
    // initialize session
    var audioRecorder: AVAudioRecorder!
    
    var recordings = [Recording]()
    
    var recording = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    
    var inputGain: Float = 0.5
    
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        if recordingSession.recordPermission != .granted {
            recordingSession.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    print("need microphone permission")
                }
            }
        }
        
        do {
            try recordingSession.setCategory(.playAndRecord,mode: .default)
            try recordingSession.setActive(true)
            try recordingSession.setInputGain(self.inputGain)
        } catch {
            print("Failed to initialize session")
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileName = documentPath.appendingPathComponent("\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder.record()
            recording = true
        } catch {
            print("Failed to start recording")
            print(error.localizedDescription)
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recording = false
        
        fetchRecordings()
    }
    
    func fetchRecordings() {
        recordings.removeAll()
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        for audio in directoryContents {
            let recording = Recording(fileURL: audio, createdAt: getCreationDate(for: audio))
            recordings.append(recording)
        }
        
        recordings.sort(by: {$0.createdAt.compare($1.createdAt) == .orderedAscending})
        
        objectWillChange.send(self)
    }
    
    func deleteRecording(urlsToDelete: [URL]) {
        for url in urlsToDelete {
            print(url)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Could not delete file \(url.lastPathComponent)")
            }
        }
        
        fetchRecordings()
    }
    
    func updateInputGain(newGain: Float) {
        self.inputGain = newGain
    }
    
    func getChannelPower() -> Float {
        return scaleChannelPower(power: self.audioRecorder.peakPower(forChannel: 0))
    }

    
}
