

import SwiftUI

@main
struct basicRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(audioRecorder: AudioRecorder())
//            ContentView()
        }
    }
}
