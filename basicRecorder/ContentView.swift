

import SwiftUI
import AVFoundation


struct ContentView: View {
    @ObservedObject var recorder: RecordingEngine = RecordingEngine()
    @State var recording: Bool = false
    @State var playing: Bool = false
    @State private var isEditing = true
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    RecordingsList(audioRecorder: recorder)
                    
                    // Meter
                    visualMeter(level: recorder.currentPower)
                    
                    // input gain slider
                    Slider (value: $recorder.inputScale,
                            in: 0.0...1.0,
                            onEditingChanged: { editing in
                                isEditing = editing
                    })
                    Text("\(recorder.inputScale)")
                                    
                    // Button
                    if recording {
                        Button(action: {
                            print("Stopping recording")
                            recording = false
                            recorder.stopRecording()
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
                                    recording = true
                                    recorder.startRecording()
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
                .navigationTitle("Please end me.")
                .toolbar{
                    ToolbarItem(placement: .automatic) {
                        EditButton()
                    }
                }
            }
            
        }
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(recorder: RecordingEngine())
//        ContentView()
    }
}
