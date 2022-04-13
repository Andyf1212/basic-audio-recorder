//import Foundation
//import AVFoundation
//import SwiftUI
//
//
//struct AudioMonitor: View {
//    
//    var channelCapture = AVCaptureAudioChannel
//    
//    var body: some View {
//        ZStack {
//            Rectangle()
//            HStack {
//                AudioBar(currentOpacity: getOpacity())
//            }
//        }
//    }
//    
//    func getLevel() {
//        audioRecorder.startRecording(self)
//    }
//    
//    func getOpacity (audioLevel: Double) -> Float {
//        return Float(abs(audioLevel))
//    }
//}
//
//struct AudioBar: View {
//    var currentOpacity = 0
//    var body: some View {
//        Rectangle()
//            .opacity(1.0)
//    }
//}
//
//struct AudioMonitor_previews: PreviewProvider {
//    static var previews: some View {
//        AudioMonitor()
//    }
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
////import Foundation
////import AVFoundation
////
////class AudioMonitor: ObservableObject {
////    var audioRecorder: AVAudioRecorder
////    var timer: Timer?
////
////    var inputGain: Float
////    var gainChanged: Bool = false
////
////    var currentSample: Int
////    let numberOfSamples: Int
////
////    @Published var soundSamples: [Float]
////
////    deinit {    // fuck you why are you only happy up here >:(
////        timer?.invalidate()
////        audioRecorder.stop()
////    }
////
////    init (numberOfSamples: Int, inputGain: Float) {
////        self.numberOfSamples = numberOfSamples
////        self.inputGain = inputGain
////        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
////        self.currentSample = 0
////
////        let audioSession = AVAudioSession.sharedInstance()
////        if audioSession.recordPermission != .granted {
////            audioSession.requestRecordPermission { (isGranted) in
////                if !(isGranted) {
////                    print("Microphone permission required...")
////                }
////            }
////        }
////
////        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
////        let recorderSettings: [String:Any] = [
////            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
////            AVSampleRateKey: 44100.0,
////            AVNumberOfChannelsKey: 1,
////            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
////        ]
////
////        do {
////            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
////            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
////
////            startMonitoring()
////        } catch {
////            fatalError(error.localizedDescription)
////        }
////
////
////        func updateInputGain(gain: Float) {
////            if audioSession.isInputGainSettable {
////                do {
////                    self.inputGain = gain
////                    try audioSession.setInputGain(gain)
////                } catch {
////                    print("Error setting monitor input gain")
////                }
////            } else {
////                print("Monitor input gain not settable")
////            }
////        }
////
////        func startMonitoring() {
////            audioRecorder.isMeteringEnabled = true
////            audioRecorder.record()
////            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
////                self.audioRecorder.updateMeters()
////                self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
////                self.currentSample = (self.currentSample + 1) % self.numberOfSamples
////            })
////        }
////
////        func getSample() -> Float {
////            return self.soundSamples[0]
////        }
////
////
////    }
////}
