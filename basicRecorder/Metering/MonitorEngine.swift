import Foundation
import AVFoundation

class MonitorEngine: ObservableObject {
    enum State {
        case monitoring, stopped, paused
    }
    
    @Published var state: State = .stopped
    var engine: AVAudioEngine!
    var mixer: AVAudioMixerNode!
    var bufSize: UInt32 = 4096
    @Published var level: [Float] = [0.0]
    @Published var liveMonitor: Bool = false
    
    let session: AVAudioSession = AVAudioSession.sharedInstance()
    let signalProcessor = SignalProcessing()
    
    // optional effects
    var eq: AVAudioUnitEQ!
    
    // eq params
    var eqGlobalGain: Float = 0.0
    
    // interruption stuff
    var isInterrupted: Bool = false
    var configChangePending: Bool = false
    
    init() {
        setupEngine()
        setupSession()
        startMonitoring()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        eq = AVAudioUnitEQ()
        
        eq.bypass = false
            
        makeConnections()
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            self.eq.globalGain = self.eqGlobalGain
        }
        
        engine.prepare()
    }
    
    func makeConnections() {
        engine.attach(mixer)
        engine.attach(eq)
        
        engine.connect(engine.inputNode, to: eq, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(eq, to: mixer, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(mixer, to: engine.mainMixerNode, format: engine.inputNode.outputFormat(forBus: 0))
        
        engine.disconnectNodeOutput(engine.mainMixerNode)
        
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
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setAllowHapticsAndSystemSoundsDuringRecording(false)
            setupNotifications()
        } catch {
            fatalError("Error setting up monitoring session: \(error.localizedDescription)")
        }
    }
    
    func setupNotifications() {
        // handle when we lose access to microphone
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] (notification) in
            
            guard let weakself = self else {return}
            
            let userInfo = notification.userInfo
            let interruptionTypeValue: UInt = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue)!
            
            switch interruptionType {
            case .began:
                weakself.isInterrupted = true
                
                if weakself.state == .monitoring {
                    weakself.pauseMonitor()
                }
            case .ended:
                weakself.isInterrupted = false
                
                try? self?.session.setActive(true, options: .notifyOthersOnDeactivation)
                
                if weakself.state == .paused {
                    try? weakself.resumeMonitor()                }
                
            @unknown default:
                break
            }
        }
        
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
    
    func startMonitoring() {
        
        eq.installTap(onBus: 0, bufferSize: bufSize, format: engine.inputNode.outputFormat(forBus: 0)) {(buffer, time) in
            self.updateLevel(buffer: buffer)
        }
        
        do {
            state = .monitoring
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try engine.start()
        } catch {
            fatalError("Error starting monitoring engine: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        engine.inputNode.removeTap(onBus: 0)
        eq.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
        do {
            try session.setActive(false)
        } catch {
            fatalError("Error deactivating monitoring session: \(error.localizedDescription)")
        }
    }
    
    func pauseMonitor() {
        engine.stop()
        state = .paused
    }
    
    func resumeMonitor() throws {
        try engine.start()
        state = .monitoring
    }
    
    func updateInputGain(gain: Float) {
        print("Monitor input gain adjusted: \(gain)")
        self.eqGlobalGain = gain
    }
    
    func updateLevel(buffer: AVAudioPCMBuffer) {
        // get level in dB
        guard let channelData = buffer.floatChannelData else {return}
        
        let channelDataValue = channelData.pointee
        
        let channelDataValueArray = stride(from: 0, through: Int(buffer.frameLength), by: buffer.stride)
            .map{channelDataValue[$0]}
        
        let rms = sqrt(channelDataValueArray.map {
            return $0 * $0
        }
            .reduce(0, +) / Float(buffer.frameLength))
        
        let avgPower = 20 * log10(rms)
        
        let meterLevel = scalePower(power: avgPower)
        
        DispatchQueue.main.async {
            self.level[0] = meterLevel
        }
    }
    
    func scalePower(power: Float) -> Float {
        guard power.isFinite else {return 0.0}

        let minDb: Float = -80

        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        }

        return (abs(minDb) - abs(power)) / abs(minDb)
    }
    
    func toggleMonitor() {
        if liveMonitor {
            // turn it off
            engine.disconnectNodeOutput(engine.mainMixerNode)
            liveMonitor = false
        } else {
            // turn it on
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
            liveMonitor = true
        }
    }
}
