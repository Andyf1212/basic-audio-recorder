import Foundation
import AVFoundation

class RecordEngine: ObservableObject {
    enum State {
        case recording, stopped, paused
    }
    
    // base variables for recording functionality
    var bufSize: UInt32 = 4096
    var engine: AVAudioEngine!
    var file: AVAudioFile?
    var mixer: AVAudioMixerNode!
    var inputLevel: Float = 1.0
    @Published var state:State = .stopped
    @Published public var level: [Float] = [0.0]
    @Published var liveMonitor: Bool = false
    
    var session: AVAudioSession = AVAudioSession.sharedInstance()
    
    // eq for input
    var eq: AVAudioUnitEQ!
    
    // eq params
    var eqGlobalGain: Float = 0.0
    
    // interruption notifications
    var isInterrupted: Bool = false
    var configChangePending = false

    
    init() {
        setupEngine()
        setupSession()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        eq = AVAudioUnitEQ()
        
        eq.bypass = false
        
        makeConnections()
        
        // input tap for input gain
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            self.eq.globalGain = self.eqGlobalGain
            // print(self.eq.globalGain)
        }
        
        engine.prepare()
    }
    
    func makeConnections() {
        engine.attach(eq)
        engine.attach(mixer)
        
        engine.connect(engine.inputNode, to: eq, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(eq, to: mixer, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(mixer, to: engine.mainMixerNode, format: engine.inputNode.outputFormat(forBus: 0))
        
    }
    
    func setupSession() {
        if session.recordPermission != .granted {
            session.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    fatalError("WE NEED MICROPHONE ACCESS YOU SELFISH ASSHOLE")
                }
            }
        }
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setAllowHapticsAndSystemSoundsDuringRecording(false)
            setupNotifications()
        } catch {
            fatalError("Error setting up recording session: \(error.localizedDescription)")
        }
    }
    
    func setupFile() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            file = try AVAudioFile(forWriting: url.appendingPathComponent(("\(Date().toString(dateFormat: "'Recording'_dd-MM-YY_'at'_HH:mm:ss")).caf")), settings: engine.inputNode.outputFormat(forBus: 0).settings)
        } catch {
            fatalError("Error generating output file: \(error.localizedDescription)")
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
                
                if weakself.state == .recording {
                    weakself.pauseRecording()
                }
            case .ended:
                weakself.isInterrupted = false
                
                try? self?.session.setActive(true, options: .notifyOthersOnDeactivation)
                
                if weakself.state == .paused {
                    try? weakself.resumeRecording()
                }
                
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
    
    func startRecording() {
        setupFile()
        
        // this is only for recording the actual file
        eq.installTap(onBus: 0, bufferSize: bufSize, format: engine.inputNode.outputFormat(forBus: 0)) { (buffer, time) in
            // do stuff with buffer here

            do {
                // print("Attempting to write to file at \(String(describing: self.file?.url.absoluteString))")
                try self.file?.write(from: buffer)
                self.updateLevel(buffer: buffer)
            } catch {
                fatalError("Error writing to file: \(error.localizedDescription)")
            }
        }
        
        do {
            state = .recording
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try engine.start()
        } catch {
            fatalError("Error starting recording engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        eq.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
        do {
            try session.setActive(false)
        } catch {
            fatalError("Error deactivating recording session: \(error.localizedDescription)")
        }
    }
    
    func pauseRecording() {
        engine.pause()
        state = .paused
    }
    
    func resumeRecording() throws {
        try engine.start()
        state = .recording
    }
    
    func updateInputGain(gain: Float) {
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
