//
//  ContentView.swift
//  basicRecorder
//
//  Created by Andy Freeman on 3/27/22.
//

import SwiftUI

struct ContentView: View {
    // *~ aesthetics *~
    @State var mainColor = Color(red:26/255, green:54/255, blue:20/255)
    @ObservedObject var audioRecorder: AudioRecorder
    
    var body: some View {
        ZStack {
            mainColor.ignoresSafeArea()
            VStack {
                HStack {
                    Text("Basic Recorder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
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
                        self.audioRecorder.startRecording()
                    }, label: {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .foregroundColor(Color.red)
                            .padding(.bottom,40)
                    })
                }
            }
            .navigationBarTitle("Basic Recorder")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(audioRecorder: AudioRecorder())
    }
}
