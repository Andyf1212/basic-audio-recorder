// fuck it we're combining the recorder and monitor maybe that'll keep things from breaking

import Foundation
import AVFoundation
import Combine

class AudioRecorderMonitor: NSObject, ObservableObject {
    // variables
    let objectWillChange = PassthroughSubject<AudioRecorderMonitor, Never>()
    var audioRecorder: AVAudioRecorder!
    var timer: Timer?
    @Published public var sample: Float = 0.0
    var recordings = [Recording]()
    var recording = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var inputGain: Float = 0.5
    
    // init
    override init() {
        super.init()
        fetchRecordings()
        startMonitoring()
    }
    
    // deinit
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
    
    // object management
    func startRecorderMonitor() {
        if recording {
            startRecording()
        } else {
            startMonitoring()
        }
    }
    
    func stopRecorderMonitor() {
        audioRecorder.stop()
        recording = false
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
                print("Could not delete file \(url.lastPathComponent)")
            }
        }
        
        fetchRecordings()
    }
    
    // audio recorder functions
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
            //try recordingSession.setInputGain(self.inputGain)
            try recordingSession.setAllowHapticsAndSystemSoundsDuringRecording(false)
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
    
    // audio monitoring functions
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    fatalError("Microphone access is required to use the app, dipshit.")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(false)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            self.sample = self.audioRecorder.averagePower(forChannel: 0)
            print(self.sample)
        })
    }
    
    func stopMonitoring() {
        audioRecorder.stop()
        timer?.invalidate()
        recording = true
    }
    
    // additional functions
    func toggleRecording() {
        if recording {
            stopRecording()
            startMonitoring()
        } else {
            stopMonitoring()
            startRecording()
        }
    }
    
    func getLevel() -> Float {
        return self.sample
    }
    
    
}
