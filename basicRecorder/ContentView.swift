

import SwiftUI
import AVFoundation


struct ContentView: View {

    @StateObject var fileManager = mFileManager()
    @StateObject var recorder = RecordEngine()
    @StateObject var monitor = MonitorEngine()
    @StateObject var player = PlaybackEngine()
    
    
    var body: some View {
        TabView {
            RecordingView()
            .tabItem {
                Image(systemName: "record.circle")
                Text("Recording")
            }
            .environmentObject(fileManager)
            .environmentObject(recorder)
            .environmentObject(monitor)
            .environmentObject(player)
//            ProcessingView()
//            .tabItem {
//                Image(systemName: "slider.vertical.3")
//                Text("Processing")
//            }
//            .environmentObject(fileManager)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
//        ContentView()
    }
}
