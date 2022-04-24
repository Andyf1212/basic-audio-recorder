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
    var inputLevel: Float = 1.0
    @Published var state:State = .stopped
    @Published var level: Float = 0.0
    
    var session: AVAudioSession = AVAudioSession.sharedInstance()
    
    // eq for input
    var eq = AVAudioUnitEQ()
    
    // eq params
    var eqGlobalGain: Float = 0.0

    
    init() {
        setupEngine()
        setupSession()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        
        eq.bypass = false
        
        engine.attach(eq)
        engine.attach(mixer)
        engine.connect(engine.inputNode, to: eq, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(eq, to: mixer, format: engine.inputNode.outputFormat(forBus: 0))
        engine.connect(mixer, to: engine.mainMixerNode, format: engine.inputNode.outputFormat(forBus: 0))
        
        // input tap for input gain
        
        mixer.installTap(onBus: 0, bufferSize: bufSize, format: mixer.outputFormat(forBus: 0)) {(buffer, time) in
            // DO PROCESSING HERE
            self.eq.globalGain = self.eqGlobalGain
            print(self.eq.globalGain)
        }
        
        engine.prepare()
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
            try session.setCategory(.record, mode: .default)
        } catch {
            fatalError("Error setting up recording session: \(error.localizedDescription)")
        }
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
        
        
        setupFile()
        
        // this is only for recording the actual file
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: bufSize, format: engine.mainMixerNode.outputFormat(forBus: 0)) { (buffer, time) in
            // do stuff with buffer here
            //var channelData = buffer.floatChannelData
            //self.eq.globalGain = self.eqGlobalGain

            do {
                try self.file?.write(from: buffer)
            } catch {
                fatalError("Error writing to file: \(error.localizedDescription)")
            }
        }
        
        do {
            state = .recording
            try session.setActive(true)
            try engine.start()
        } catch {
            fatalError("Error starting recording engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        engine.mainMixerNode.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
        do {
            try session.setActive(false)
        } catch {
            fatalError("Error deactivating recording session: \(error.localizedDescription)")
        }
    }
    
    func updateInputGain(gain: Float) {
        self.eqGlobalGain = gain
    }
}
