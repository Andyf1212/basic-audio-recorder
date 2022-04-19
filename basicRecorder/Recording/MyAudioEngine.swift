//
//  MyAudioEngine.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/17/22.
//

import Foundation
import AVFoundation
import Combine

class Recorder {
    enum RecordingState {
        case recording, pause, stopped
    }
    
    private var engine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    public var state: RecordingState = .stopped
    
    var converter: AVAudioConverter!
    var compressedBuffer: AVAudioCompressedBuffer!
    
    fileprivate var isInterrupted: Bool = false
    fileprivate var configChangePending = false
    
    var recordings = [Recording]()
    
    init() {
        setupSession()
        setupEngine()
    }
    
    // file management
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
    
    fileprivate func setupSession() {
        let session = AVAudioSession.sharedInstance()
        
        // get microphone permissions
        if session.recordPermission != .granted {
            session.requestRecordPermission { (isGranted) in
                if !(isGranted) {
                    print("NEED MICROPHONE PERMISSION DIPSHIT")
                }
            }
        }
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func setupEngine() {
        engine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        
        mixerNode.volume = 0
        
        makeConnections()
        
        engine.prepare()
    }
    
    fileprivate func makeConnections() {
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        engine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        let mainMixerNode = engine.mainMixerNode
        let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: false)
        engine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }
    
    func startRecording() throws {
        let tapNode: AVAudioNode = mixerNode
        let format = tapNode.outputFormat(forBus: 0)
        
        // format handling
        var outDesc = AudioStreamBasicDescription()
        outDesc.mSampleRate = format.sampleRate
        outDesc.mChannelsPerFrame = 1
        outDesc.mFormatID = kAudioFormatAppleLossless
        
        let framesPerPacket: UInt32 = 1152
        outDesc.mFramesPerPacket = framesPerPacket
        outDesc.mBitsPerChannel = 24
        outDesc.mBytesPerPacket = 0
        
        let convertFormat = AVAudioFormat(streamDescription: &outDesc)!
        converter = AVAudioConverter(from: format, to: convertFormat)
        
        let packetSize: UInt32 = 8
        let bufferSize = framesPerPacket * packetSize
        
        // file writing
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let file = try AVAudioFile(forWriting: documentURL.appendingPathComponent("\(Date().toString(dateFormat: "'ENGINE'_dd-MM-YY_'at'_HH:mm:ss")).m4a"), settings: format.settings)
        
        tapNode.installTap(onBus: 0, bufferSize: bufferSize, format: format, block: {[weak self] (buffer, time) in
            guard let weakself = self else {
                return
            }
            
            weakself.compressedBuffer = AVAudioCompressedBuffer(
                format: convertFormat, packetCapacity: packetSize, maximumPacketSize: weakself.converter.maximumOutputPacketSize)
            
            let inputBlock: AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer in
                outStatus.pointee = AVAudioConverterInputStatus.haveData;
                return buffer;  // fill and return input buffer
            }
            
            // conversion loop
            var outError: NSError? = nil
            weakself.converter.convert(to: weakself.compressedBuffer!, error: &outError, withInputFrom: inputBlock)
            
            let audioBuffer = weakself.compressedBuffer!.audioBufferList.pointee.mBuffers
            if let mData = audioBuffer.mData {
                let length = Int(audioBuffer.mDataByteSize)
                let data: NSData = NSData(bytes: mData, length: length)
                
                // DO STUFF WITH THE DATA HERE
            } else {
                print("Error")
            }
            try? file.write(from: buffer)
        })
        
        try engine.start()
        state = .recording
    }
    
    func resumeRecording() throws {
        try engine.start()
        state = .recording
    }
    
    func pauseRecording() {
        engine.pause()
        state = .pause
    }
    
    func stopRecording() {
        mixerNode.removeTap(onBus: 0)
        engine.stop()
        converter.reset()
        state = .stopped
    }
    
    fileprivate func handleConfigurationChange() {
        if configChangePending {
            makeConnections()
        }
        configChangePending = false
    }
    
    fileprivate func registerForNotifications() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil)
        { [weak self] (notifications) in
            guard let weakself = self else {
                return
            }
            
            let userInfo = notifications.userInfo
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
                
                // activate session again
                try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                
                weakself.handleConfigurationChange()
                
                if weakself.state == .pause {
                    try? weakself.resumeRecording()
                }
            default:
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AVAudioEngineConfigurationChange, object: nil, queue: nil)
        { [weak self] (notification) in
            guard let weakself = self else {
                return
            }
            
            weakself.configChangePending = true
            
            if (!weakself.isInterrupted) {
                weakself.handleConfigurationChange()
            } else {
                print("deferring changes")
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) {[weak self] (notification) in
            guard let weakself = self else {
                return
            }
            
            weakself.setupSession()
            weakself.setupEngine()
        }
    }
}
