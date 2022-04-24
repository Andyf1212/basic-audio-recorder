

import SwiftUI
import AVFoundation


struct ContentView: View {

    @ObservedObject var recorder: RecordEngine = RecordEngine()
    @ObservedObject var monitor: MonitorEngine = MonitorEngine()
    var fileManager:mFileManager = mFileManager()
    
    @State var showingAlert: Bool = false
    @State var sliderLevel: Float = 0.0
    
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    // list of recordings
                    RecordingsList(fileManager: fileManager)
                    
                    // VU meter
                    if recorder.state == .recording {
                        // CASE RECORDING
                        visualMeter(level: recorder.level)
                        Text("\(recorder.level)")
                    } else if monitor.state == .monitoring {
                        visualMeter(level: monitor.level)
                        Text("\(monitor.level)")
                    }
                    
                    // Gain Slider
                    Slider (value: $sliderLevel, in: -96...24) { _ in
                        monitor.updateInputGain(gain: sliderLevel)
                        recorder.updateInputGain(gain: sliderLevel)
                    }
                    .padding()
                    Text("\(sliderLevel)")
                    
                    // Record button
                    if monitor.state == .stopped {
                        // CASE RECORDING
                        Button(action: {
                            print("Stopping recording")
                            recorder.stopRecording()
                            fileManager.fetchRecordings()
                            monitor.startMonitoring()
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
                        // CASE NOT RECORDING
                        Button(action: {
                            print("Starting recording")
                            monitor.stopMonitoring()
                            recorder.startRecording()
                        }, label: {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .foregroundColor(Color.red)
                                .padding(.bottom, 40)
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
        .environmentObject(monitor)
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
//        ContentView()
    }
}
