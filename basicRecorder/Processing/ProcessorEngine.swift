//
//  ProcessorEngine.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/24/22.
//

import Foundation
import AVFoundation
import Combine


class ProcessorEngine: ObservableObject {
    var engine: AVAudioEngine!
    var mixer: AVAudioMixerNode!
    var player: AVAudioPlayerNode!
    var session = AVAudioSession.sharedInstance()
    var srcUrl: URL
    var outFile: AVAudioFile?
    var configChangePending: Bool = false
    var isInterrupted: Bool = false
    var eq: AVAudioUnitEQ!
    var reverb: AVAudioUnitReverb!
    var distortion: AVAudioUnitDistortion!
    @Published var state: State = .stopped
    @Published var level: Float = 0.0
    
    // to be initialized
    var audioFile: AVAudioFile!
    
    // configuration
    var bufSize: UInt32 = 4096
    var eqEnabled: Bool = false
    var reverbEnabled: Bool = false
    var distortionEnabled: Bool = false
    
    var numEQBands: Int = 2
    
    enum State {
        case stopped, processing, paused, rendering
    }
    
    init(audioFileUrl: URL, bypassFX: Bool = false) {
        srcUrl = audioFileUrl
        
        setupEngine()
        setupSession()
        setupFile()
        
        if bypassFX {
            enableFX(eqEnabled: false, reverbEnabled: false, distortionEnabled: false)
        }
    }
    
    deinit {
        
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        mixer = AVAudioMixerNode()
        
        setupFX()
        
        makeConnections()
        
        engine.prepare()
    }
    
    func setupSession() {
        // no need to check for mic permissions as this is only file playback
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            setupNotifications()
        } catch {
            fatalError("Error setting up processing session: \(error.localizedDescription)")
        }
    }
    
    func setupFX() {
        // configure eq -> CURRENTLY CONFIGURED FOR TWO CUTOFF BANDS
        eq = AVAudioUnitEQ(numberOfBands: numEQBands)
        eq.bands[0].filterType = .highPass
        eq.bands[0].frequency = 4000.0
        eq.bands[1].filterType = .lowPass
        eq.bands[1].frequency = 8000.0
        
        // configure distortion
        distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.multiEverythingIsBroken)
        distortion.wetDryMix = 50.0     // 50% blend
        
        // configure reverb
        reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.plate)
        reverb.wetDryMix = 50.0         // 50% blend
    }
    
    func enableFX(eqEnabled: Bool, reverbEnabled: Bool, distortionEnabled: Bool) {
        // set the bypass on each
        enableEQ(eqEnabled: eqEnabled)
        enableDistortion(distortionEnabled: distortionEnabled)
        enableReverb(reverbEnabled: reverbEnabled)
    }
    
    func enableEQ(eqEnabled: Bool) {
        if eqEnabled {
            eq.bypass = false
        } else {
            eq.bypass = true
        }
    }
    
    func enableReverb(reverbEnabled: Bool) {
        if reverbEnabled {
            reverb.bypass = false
        } else {
            reverb.bypass = true
        }
    }
    
    func enableDistortion(distortionEnabled: Bool) {
        if distortionEnabled {
            distortion.bypass = false
        } else {
            distortion.bypass = true
        }
    }
    
    func setupFile() {
        // input
        do {
            let isReachable = try srcUrl.checkResourceIsReachable()
            print("\(srcUrl.absoluteString) rechable: \(isReachable)")
            try audioFile = AVAudioFile(forReading: srcUrl)
        } catch {
            fatalError("Error loading source file \(srcUrl.absoluteString): \(error.localizedDescription)")
        }
    }
    
    func setupOutFile() {
        // get current file name
        let currentName = srcUrl.lastPathComponent
        let outUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            outFile = try AVAudioFile(forWriting: outUrl.appendingPathComponent(("RENDERED_\(currentName)")), settings: engine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            fatalError("Error generating processor output file: \(error.localizedDescription)")
        }
    }
    
    func makeConnections() {
        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.attach(eq)
        engine.attach(reverb)
        engine.attach(distortion)
        engine.attach(mixer)
        engine.attach(player)
        
        // eq into reverb... both mixed into distortion
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: distortion, format: format)
        engine.connect(distortion, to: reverb, format: format)
        engine.connect(reverb, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        
        // level capture / file write tap
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: format) { (buffer, time) in
            // DO STUFF HERE
            
            // write to file if that's the option right now
            if self.state == .rendering {
                do {
                    try self.outFile?.write(from: buffer)
                } catch {
                    fatalError("Error writing rendered file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func setupNotifications() {
        // handle when any configuration change occurs
        NotificationCenter.default.addObserver(forName: Notification.Name.AVAudioEngineConfigurationChange, object: nil, queue: nil) {[weak self] (Notification) in
            
            guard let weakself = self else {return}
            
            weakself.configChangePending = true
            
            if (!weakself.isInterrupted) {
                weakself.handleConfigurationChange()
            } else {
                print("Deferring hardware changes")
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) {[weak self] (notification) in
            
            guard let weakself = self else {return}
            
            weakself.setupSession()
            weakself.setupEngine()
        }
    }
    
    func handleConfigurationChange() {
        if configChangePending {
            makeConnections()
        }
        configChangePending = false
    }
    
    func startPlayback() {
        try? session.setActive(true)
        
        player.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { _ in
            // post-playback processing
            DispatchQueue.main.async {
                self.state = .stopped
            }
            self.engine.stop()
        }
        
        do {
            self.state = .processing
            try engine.start()
            player.play()
        } catch {
            fatalError("Error starting processing playback: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        if self.player.isPlaying {
            self.player.stop()
        }
        self.engine.stop()
        self.state = .stopped
    }
    
    func pausePlayback() {
        self.state = .paused
        player.pause()
        engine.pause()
    }
    
    func resumePlayback() throws {
        self.state = .processing
        try engine.start()
        player.play()
    }
}
