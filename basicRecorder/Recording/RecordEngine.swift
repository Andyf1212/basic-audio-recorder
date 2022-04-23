//
//  RecordEngine.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/22/22.
//

import Foundation
import AVFoundation

class RecordEngine: ObservableObject {
    enum State {
        case recording, stopped
    }
    
    // base variables for recording functionality
    var bufSize: UInt32 = 4096
    var engine: AVAudioEngine!
    var file: AVAudioFile?
    var mixer: AVAudioMixerNode!
    @Published var state:State = .stopped
    @Published var level: Float = 0.0
    
    var signalProcessor = SignalProcessing()

    
    init() {
        setupEngine()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        
        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: engine.inputNode.outputFormat(forBus: 0))
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            
            DispatchQueue.main.async {
                self.level = self.signalProcessor.translatedPower(buffer: buffer)[0]
            }
        }
        
        engine.prepare()
    }
    
    func setupFile() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            file = try AVAudioFile(forWriting: url.appendingPathComponent(("\(Date().toString(dateFormat: "'NEW-ENGINE'_dd-MM-YY_'at'_HH:mm:ss")).caf")), settings: engine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            fatalError("Error generating output file: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission != .granted {
            session.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    fatalError("WE NEED MICROPHONE ACCESS YOU SELFISH ASSHOLE")
                }
            }
        }
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            fatalError("Error setting up recording session: \(error.localizedDescription)")
        }
        
        setupFile()
        
        // this is only for recording the actual file
        engine.inputNode.installTap(onBus: 0, bufferSize: bufSize, format: engine.inputNode.outputFormat(forBus: 0)) { (buffer, time) in
            // do stuff with buffer here

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
            fatalError("Error starting recording engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
    }
}
