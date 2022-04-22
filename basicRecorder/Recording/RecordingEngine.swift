//
//  RecordingEngine.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/17/22.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

class RecordingEngine: ObservableObject {
    enum RecordingState {
        case recording, paused, stopped, playing, monitoring
    }
    
    let bufSize: UInt32 = 4096
    let fileSettings = [
        AVFormatIDKey: Int(kAudioFormatAppleLossless),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    let objectWillChange = PassthroughSubject<RecordingEngine, Never> ()
    var engine: AVAudioEngine = AVAudioEngine()
    var file: AVAudioFile?
    var player: AVAudioPlayerNode = AVAudioPlayerNode()
    var state: RecordingState = .stopped
    @Published var currentPower: Float = 0.0
    @Published var inputScale: Float = 1.0
    
    var meter: visualMeter!
    
    var recordings = [Recording]()
    
    // init
    init() {
        print("initializing recording engine")
        fetchRecordings()
        setupEngine()
       // startMonitoring()
    }
    
    // set up the engine
    func setupEngine() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.outputNode, format: engine.inputNode.outputFormat(forBus: 0))
        
        player.installTap(onBus: 0, bufferSize: bufSize, format: player.outputFormat(forBus: 0)) { (buffer, time) in
            // DO PLAYBACK PROCESSING HERE
        }
        
        engine.prepare()
    }
    
    // set up the recording
    func startRecording() {
        stopMonitoring()
        // set up audio session
        let session = AVAudioSession.sharedInstance()
        
        setupFile()
        
        if session.recordPermission != .granted {
            session.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    print("NEED MICROPHONE ACCESS, DIPSHIT")
                }
            }
        }
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            fatalError("Error setting up recording session: \(error.localizedDescription)")
        }
        
        // set up tap note to write buffers to file
        engine.inputNode.installTap(onBus: 0, bufferSize: bufSize, format: engine.inputNode.outputFormat(forBus: 0)) { (buffer, time) in
            // do stuff with buffer here
            // input volume
            
            
            self.currentPower = self.returnPower(buffer: buffer)
            // self.objectWillChange.send(self)
            do {
                try self.file?.write(from: buffer)
            } catch {
                fatalError("Error writing to file: \(error.localizedDescription)")
            }
        }
        
        do {
            state = .recording
            try engine.start()
        } catch {
            fatalError("Error starting engine: \(error.localizedDescription)")
        }
    }
    
    // control the recording
    func stopRecording() {
        if state == .recording {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            state = .stopped
            fetchRecordings()
            startMonitoring()
        } else {
            print("Error: Wrong state at recording stop.")
        }
    }
    
    // set up the file
    func setupFile() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            file = try AVAudioFile(forWriting: url.appendingPathComponent(("\(Date().toString(dateFormat: "'ENGINE'_dd-MM-YY_'at'_HH:mm:ss")).caf")), settings: engine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            fatalError("Error creating output file: \(error.localizedDescription)")
        }
    }
    
    // recording file management
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
                fatalError("Could not delete file \(url.lastPathComponent)")
            }
        }
        
        fetchRecordings()
    }
    
    // playback
    func startPlayback(url: URL) {
        stopMonitoring()
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
        } catch {
            fatalError("Error initializing playback session: \(error.localizedDescription)")
        }
        
        var audioFile: AVAudioFile!
        
        do {
            try audioFile = AVAudioFile(forReading: url)
        } catch {
            fatalError("Error loading playback file: \(error.localizedDescription)")
        }
        
        player.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { _ in
            // post-player handling here
        }
        
        
        
        do {
            state = .playing
            try engine.start()
            player.play()
        } catch {
            fatalError("Error starting file playback: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        if state == .playing {
            print("File playback ended")
            player.removeTap(onBus: 0)
            player.stop()
            engine.stop()
            state = .stopped
            startMonitoring()
        } else {
            print("Error: wrong state found when stopping playback")
        }
    }
    
    // helper functions
    func isPlaying() -> Bool {
        if self.state == .playing {
            return true
        } else {
            return false
        }
    }
    
    // monitoring
    func startMonitoring() {
        // set up audio session
        let session = AVAudioSession.sharedInstance()
        
        if session.recordPermission != .granted {
            session.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    print("NEED MICROPHONE ACCESS, DIPSHIT")
                }
            }
        }
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            fatalError("Error setting up recording session: \(error.localizedDescription)")
        }
        
        // set up tap note to write buffers to file
        engine.inputNode.installTap(onBus: 0, bufferSize: bufSize, format: engine.inputNode.outputFormat(forBus: 0)) { (buffer, time) in
            // do stuff with buffer here
            // input volume
            
            
            // self.objectWillChange.send(self)
            
        }
        
        do {
            try engine.start()
            state = .monitoring
        } catch {
            fatalError("Error starting monitor: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
    }
    
    func returnPower(buffer: AVAudioPCMBuffer) -> Float{
        let channelData = buffer.floatChannelData
          
        let channelDataValue = channelData!.pointee

          let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride)
            .map { channelDataValue[$0] }
          
          let rms = sqrt(channelDataValueArray.map {
            return $0 * $0
          }
          .reduce(0, +) / Float(buffer.frameLength))
          
          let avgPower = 20 * log10(rms)
        
        return avgPower
        
    }
    
    
}
