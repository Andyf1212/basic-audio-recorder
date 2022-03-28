

import SwiftUI
import AVFoundation


struct ContentView: View {
    // *~ aesthetics *~
    @State var mainColor = Color(red:26/255, green:54/255, blue:20/255)
    @ObservedObject var audioRecorder: AudioRecorder
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2
        return CGFloat(level * (300/25))
    }
    
    var body: some View {
        ZStack {
            mainColor.ignoresSafeArea()
            NavigationView {
                VStack {
                    HStack {
                        Text("Basic Recorder")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.leading)
                            .padding()
                        Spacer()
                    }
                    RecordingsList(audioRecorder: audioRecorder)
                    
                    if audioRecorder.recording {
                        Button(action: {
                            print("Stopping recording")
                            self.audioRecorder.stopRecording()
                        }, label: {
                            Image(systemName: "stop.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .foregroundColor(Color.red)
                                .padding(.bottom, 40)
                        })
                    } else {
                        Button (action: {
                            print("Starting recording")
                            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                                if granted {
                                    self.audioRecorder.startRecording()
                                } else {
                                    print("Need microphone access.")
                                }
                            }
                        }, label: {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .foregroundColor(Color.red)
                                .padding(.bottom,40)
                        })
                    }
                }
                .navigationTitle("We do be recording")
                .toolbar {
                    ToolbarItem(placement:.automatic) {
                        EditButton()
                    }
                }
            }
        }
    }
}


//let numberOfSamples: Int = 10
//
//struct ContentView: View {
//    @ObservedObject private var mic = AudioMonitor(numberOfSamples: numberOfSamples)
//
//    private func normalizeSoundLevel(level: Float) -> CGFloat {
//        // dBFS scales from -160 [min] to 0 [max]
//        let normalized = (300 * (level + 160) / (160))
//        print(normalized)
//        print(level)
//
//        return CGFloat(normalized)
//    }
//
//    var body: some View {
//        VStack {
////            HStack (spacing: 4) {
////                ForEach(mic.soundSamples, id: \.self) {level in
////                    BarView(value: self.normalizeSoundLevel(level: level))
////                }
////            }
//            LevelMeter(level: self.normalizeSoundLevel(level: mic.soundSamples[mic.soundSamples.count-1]))
//        }
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(audioRecorder: AudioRecorder())
//        ContentView()
    }
}
