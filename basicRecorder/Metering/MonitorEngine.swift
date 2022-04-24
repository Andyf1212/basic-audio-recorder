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
    @Published var level: Float = 0.0
    
    let session: AVAudioSession = AVAudioSession.sharedInstance()
    let signalProcessor = SignalProcessing()
    
    // optional effects
    var eq: AVAudioUnitEQ!
    
    // eq params
    var eqGlobalGain: Float = 0.0
    
    init() {
        setupEngine()
        setupSession()
        startMonitoring()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        eq = AVAudioUnitEQ()
            
        // create the signal chain
        
        engine.attach(mixer)
        engine.attach(eq)
        
        engine.connect(mixer, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
        engine.connect(eq, to: mixer, format: engine.inputNode.outputFormat(forBus: 0))
        
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            self.eq.globalGain = self.eqGlobalGain
            //print(self.eqGlobalGain)
            
        }
        
        engine.prepare()
    }
    
    func setupSession() {
        if session.recordPermission != .granted {
            session.requestRecordPermission {(isGranted) in
                if !(isGranted) {
                    fatalError("need microphone access, bozo")
                }
            }
        }
        do {
            try session.setCategory(.playAndRecord, mode: .measurement)
        } catch {
            fatalError("Error setting up monitoring session: \(error.localizedDescription)")
        }
    }
    
    func startMonitoring() {
        do {
            state = .monitoring
            try engine.start()
            try session.setActive(true)
        } catch {
            fatalError("Error starting monitoring engine: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
        do {
            try session.setActive(false)
        } catch {
            fatalError("Error deactivating monitoring session: \(error.localizedDescription)")
        }
    }
    
    func updateInputGain(gain: Float) {
        print("Monitor input gain adjusted: \(gain)")
        self.eqGlobalGain = gain
    }
}
