//
//  ProcessingView.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/25/22.
//

import SwiftUI

struct ProcessingView: View {
    @EnvironmentObject var fileManager: mFileManager
    @State var toggledRecording: Recording!
    @State var recordingSelected = false
    
    @State var eqShown = false
    @State var distortionShown = false
    @State var reverbShown = false
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    // file selection
                    ForEach(fileManager.recordings, id: \.createdAt) { recording in
                        ProcessRow(processor: ProcessorEngine(audioFileUrl: recording.fileURL, bypassFX: true))
                    }
                }
                .listStyle(.automatic)
                

                VStack {
                    if recordingSelected {
                        Text("\(toggledRecording.fileURL.lastPathComponent)")
                        Button(action: {
                            recordingSelected = false
                        }, label: {
                            Text("Close")
                                .foregroundColor(Color.red)
                        })

                        TabView {
                            eqWindow(audioURL: toggledRecording.fileURL)
                                .tabItem({
                                    Image(systemName: "slider.vertical.3")
                                    Text("EQ")
                                })
                            distortionWindow(audioURL: toggledRecording.fileURL)
                                .tabItem({
                                    Image(systemName: "sum")
                                    Text("Distortion")
                                })
                            reverbWindow(audioURL: toggledRecording.fileURL)
                                .tabItem({
                                    Image(systemName: "wand.and.rays")
                                    Text("Reverb")
                                })
                            
                        }
                    }
                }
                .onAppear(perform: {
                    print("appeared")
                })
                .animation(.spring(), value: recordingSelected)
            }
            .environmentObject(fileManager)
        }
    }
    
}

struct ProcessRow: View {
    @ObservedObject var processor: ProcessorEngine
    @State var toggled = false
    
    var body: some View {
        HStack {
            Text("\(processor.srcUrl.lastPathComponent)")
            
            Spacer()
            
            Button(action: {
                toggled = true
            }, label: {
                Image(systemName: "dial.max.fill")
                Text("Edit")
            })
            .buttonStyle(BorderedButtonStyle())
            
            if processor.state == .stopped {
                Button(action: {
                    processor.startPlayback()
                }, label: {
                    Image(systemName: "play.fill")
                })
                .buttonStyle(BorderedButtonStyle())
                .padding()
            } else if processor.state == .processing {
                Button(action: {
                    processor.stopPlayback()
                }, label: {
                    Image(systemName: "stop.fill")
                })
                .buttonStyle(BorderedButtonStyle())
                .padding()
            }
        }
    }
}

struct eqWindow: View {
    var audioURL: URL

    var body: some View {

        ZStack {
            Button(action: {
                print("EQ Button")
            }, label: {
                Text("Button")
            })
            
        }
        
    }
}

struct distortionWindow: View {
    var audioURL: URL
    
    var body: some View {
        ZStack {
            Button(action: {
                print("Distortion button")
            }, label: {
                Text("Button")
            })
        }
    }
}

struct reverbWindow: View {
    var audioURL: URL
    
    var body: some View {
        ZStack {
            Button(action: {
                print("reverb button")
            }, label: {
                Text("Button")
            })
        }
    }
}

struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView()
    }
}
