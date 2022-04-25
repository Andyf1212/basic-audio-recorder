//
//  RecordingView.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/25/22.
//

import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var recorder: RecordEngine
    @EnvironmentObject var monitor: MonitorEngine
    @EnvironmentObject var player: PlaybackEngine
    @EnvironmentObject var fileManager: mFileManager
    
    @State var outLevel: Float = 0.0
    @State var showingAlert: Bool = false
    @State var sliderLevel: Float = 0.0
    @State var monitorToggle: Bool = false
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    // list of recordings
                    RecordingsList(processing: false)
                    
                    // VU meter
                    if recorder.state == .recording {
                        ForEach(recorder.level, id: \.self) { level in
                            visualMeter(level: level)
//                            Text("\(level)")
                        }
                    } else if player.state == .playing {
                        ForEach(player.level, id: \.self) { level in
                            visualMeter(level: level)
//                            Text("\(level)")
                        }
                    } else if monitor.state == .monitoring {
                        ForEach(monitor .level, id: \.self) { level in
                            visualMeter(level: level)
//                            Text("\(level)")
                        }
                    }
                    
                    
                    // Gain Slider
                    HStack {
                        Button(action: {
                            sliderLevel = 0.0
                            monitor.updateInputGain(gain: sliderLevel)
                            recorder.updateInputGain(gain: sliderLevel)
                        }, label: {
                            Text("Reset Gain")
                        })
                        Slider (value: $sliderLevel, in: -96...24) { _ in
                            monitor.updateInputGain(gain: sliderLevel)
                            recorder.updateInputGain(gain: sliderLevel)
                        }
                        .padding()
                    }
                    Text("\(sliderLevel)")
                    
                    HStack {
//                        if monitorToggle {
//                            Button(action: {
//                                self.monitorToggle = false
//                                if recorder.liveMonitor == true {
//                                    recorder.toggleMonitor()
//                                }
//                                if monitor.liveMonitor == true {
//                                    monitor.toggleMonitor()
//                                }
//                            }, label: {
//                                Text("Enable Monitoring")
//                            })
//                        } else {
//                            Button(action: {
//                                self.monitorToggle = true
//                                if recorder.liveMonitor == false {
//                                    recorder.toggleMonitor()
//                                }
//                                if monitor.liveMonitor == false {
//                                    monitor.toggleMonitor()
//                                }
//                            }, label: {
//                                Text("Disable Monitoring")
//                            })
//                        }
                        
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
                }
                .navigationTitle("Hello, Finalize")
                .toolbar{
                    ToolbarItem(placement: .automatic) {
                        EditButton()
                    }
                }
            }
        }
        .environmentObject(fileManager)
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
