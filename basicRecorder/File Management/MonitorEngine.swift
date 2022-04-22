//
//  MonitorEngine.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/22/22.
//

import Foundation
import AVFoundation

class MonitorEngine: ObservableObject {
    enum State {
        case monitoring, stopped
    }
    
    @Published var state: State = .stopped
    var engine: AVAudioEngine!
    var mixer: AVAudioMixerNode!
    var bufSize: UInt32 = 4096
    
    init() {
        setupEngine()
        startMonitoring()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            
        }
        
        engine.prepare()
    }
    
    func startMonitoring() {
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission != .granted {
            session.requestRecordPermission {(isGranted) in
                if !(isGranted) {
                    fatalError("need microphone access, bozo")
                }
            }
        }
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            fatalError("Error setting up monitoring session: \(error.localizedDescription)")
        }
        
        do {
            state = .monitoring
            try engine.start()
        } catch {
            fatalError("Error starting monitoring engine: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        engine.stop()
        state = .stopped
    }
}
