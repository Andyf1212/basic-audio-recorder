import Foundation
import AVFoundation

class PlayEngine: ObservableObject {
    // new audio engine just for playback
    enum State {
        case playing, stopped, paused
    }
    
    @Published var state:State = .stopped
    var engine: AVAudioEngine!
    var file: URL!
    var player: AVAudioPlayerNode!
    var bufSize: UInt32 = 4096
    
    // optional effects
    var eq = AVAudioUnitEQ()
    
    // eq params
    var eqGlobalGain: Float = 0.0   // scales from -96dB to +24dB
    
    init() {
        setupEngine()
    }
    
    func setupEngine() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
        
        player.installTap(onBus: 0, bufferSize: bufSize, format: player.outputFormat(forBus: 0)) { (buffer, time) in
            // do playback stuff here
            
        }
        
        engine.prepare()
    }
    
    func startPlayback(fileURL: URL) {
        file = fileURL
        
        if state == .stopped {
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setCategory(.playback, mode: .default)
            } catch {
                fatalError("Error starting playback: \(error.localizedDescription)")
            }
            
            var audioFile: AVAudioFile!
            
            do {
                let isReachable = try file.checkResourceIsReachable()
                print("\(fileURL.absoluteString) reachable: \(isReachable)")
                try audioFile = AVAudioFile(forReading: file)
            } catch {
                fatalError("Error loading playback file \(fileURL.absoluteString): \(error.localizedDescription)")
            }
            
            player.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                // post playback handling here
                self.state = .stopped
                self.player.removeTap(onBus: 0)
                self.engine.stop()
            }
            
            do {
                state = .playing
                try engine.start()
                player.play()
            } catch {
                fatalError("Error starting playback: \(error.localizedDescription)")
            }
        } else {
            print("Attempted to start playback at wrong state...")
        }
    }
    
    func stopPlayback() {
        print("ending file playback")
        if self.player.isPlaying {
            self.player.stop()
        }
        self.player.removeTap(onBus: 0)
        self.engine.stop()
        self.state = .stopped
    }
    
    func isPlaying() -> Bool {
        if state == .playing {
            return true
        } else {
            return false
        }
    }
}
