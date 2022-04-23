

import SwiftUI
import AVFoundation


struct ContentView: View {

    @ObservedObject var recorder: RecordEngine
    @ObservedObject var monitor: MonitorEngine
    var fileManager: mFileManager
    
    @State var showingAlert: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    // list of recordings
                    RecordingsList(fileManager: fileManager)
                    
                    // VU meter
                    if monitor.state == .stopped {
                        // CASE RECORDING
                        visualMeter(level: recorder.level)
                        Text("\(recorder.level)")
                    }
                    
                    // Gain Slider
                    
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
    }
    
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(recorder: RecordEngine(), monitor: MonitorEngine(), fileManager: mFileManager())
//        ContentView()
    }
}
