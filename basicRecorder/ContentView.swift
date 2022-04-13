

import SwiftUI
import AVFoundation


struct ContentView: View {
    // *~ aesthetics *~
    @State var mainColor = Color(red:26/255, green:54/255, blue:20/255)
    @ObservedObject var audioRecorder: AudioRecorder
//    @ObservedObject var audioMonitor: AudioMonitor
    
    @State var inputGain: Float = 0.5
    @State private var isEditing: Bool = false
    
    @State var currentLevel: Float = 0.0
    
    var body: some View {
        ZStack {
            mainColor.ignoresSafeArea()
            NavigationView {
                VStack {
                    
                // Recording List
                    RecordingsList(audioRecorder: audioRecorder)
                    
                // monitoring bar
                    visualMeter(level: inputGain)
                    Text("Current level: \(currentLevel)")
                    
                // Input Gain Slider
                    Slider (
                        value: $inputGain,
                        in: 0.0...100.0,
                        onEditingChanged: {editing in
                            isEditing = editing
                        }
                    )
                        .padding()
                    Text("\(inputGain)")
                    
                // Button
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
                .navigationTitle("I'm going to kill myself.")
                .toolbar {
                    ToolbarItem(placement:.automatic) {
                        EditButton()
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(audioRecorder: AudioRecorder())
//        ContentView()
    }
}
