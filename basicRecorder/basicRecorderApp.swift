//
//  basicRecorderApp.swift
//  basicRecorder
//
//  Created by Andy Freeman on 3/27/22.
//

import SwiftUI

@main
struct basicRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(audioRecorder: AudioRecorder())
        }
    }
}
