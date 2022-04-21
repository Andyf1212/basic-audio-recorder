//
//  TestView.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/20/22.
//

import SwiftUI

struct TestView: View {
    var newEngine = NewEngine()
    
    var body: some View {
        VStack {
            Button(action: {
                do {
                    try newEngine.startRecording()
                } catch {
                    print("Failed to record with test view")
                }
            }, label: {
                Text("Start Recording")
            })
            
            Button(action: {
                newEngine.stopRecording()
            }, label: {
                Text("Stop recording")
            })
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
