

import SwiftUI
import AVFoundation


struct ContentView: View {
    // *~ aesthetics *~
    @State var mainColor = Color(red:26/255, green:54/255, blue:20/255)
    @ObservedObject var audioRecorder: AudioRecorderMonitor
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            mainColor.ignoresSafeArea()
            NavigationView {
                VStack {
                    
                // Recording List
                    RecordingsList(audioRecorder: audioRecorder)
                    
                // monitoring bar
                    visualMeter(level: self.audioRecorder.getLevel())
                    Text("Level: \(audioRecorder.sample)") // FUCK FUCK WHY WIULL YOU NOT UPDATE FAUWAKDVAJK CJCDKSFJASKLOFJDNA
                    
                // Input Gain Slider
                    Slider (
                        value: $audioRecorder.inputGain,
                        in: 0.0...100.0,
                        onEditingChanged: {editing in
                            isEditing = editing
                        }
                    )
                        .padding()
                        Text("\(self.audioRecorder.inputGain)")
                    
                // Button
                    if audioRecorder.recording {
                        Button(action: {
                            print("Stopping recording")
                            self.audioRecorder.toggleRecording()
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
                                    self.audioRecorder.toggleRecording()
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
        ContentView(audioRecorder: AudioRecorderMonitor())
//        ContentView()
    }
}
