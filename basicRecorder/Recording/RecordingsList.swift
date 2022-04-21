

import SwiftUI

struct RecordingsList: View {
    
    @ObservedObject var audioRecorder: RecordingEngine
    
    var body: some View {
        List {
            ForEach(audioRecorder.recordings, id: \.createdAt) {recording in
                RecordingRow(audioURL: recording.fileURL)
            }
            .onDelete(perform: delete)
        }
    }
    
    func delete (at offsets: IndexSet) {
        var urlsToDelete = [URL]()
        for index in offsets {
            urlsToDelete.append(audioRecorder.recordings[index].fileURL)
        }
        audioRecorder.deleteRecording(urlsToDelete: urlsToDelete)
    }
}

struct RecordingRow: View {
    
    var audioURL: URL
    
    @ObservedObject var audioPlayer = RecordingEngine()
    @State private var showingAlert = false
    
    var body: some View {
        HStack {
            Text("\(audioURL.lastPathComponent)")
            Spacer()
            Button(action: {
                showingAlert = true
                let alert = UIAlertController(title: "Rename File", message: nil, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addTextField(configurationHandler: {textField in
                    textField.placeholder = "Input"
                })
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: {action in
                    if let name = alert.textFields?.first?.text {
                        print(name)
                    }
                }))
            }, label: {
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .imageScale(.large)
            })
            if self.audioPlayer.state != .playing {
                Button(action: {
                    print("Starting audio playback on \(audioURL.lastPathComponent)")
                    self.audioPlayer.startPlayback(url: audioURL)
                }, label: {
                    Image(systemName: "play.circle")
                        .imageScale(.large)
                })
            } else {
                Button(action: {
                    print("Stopping audio playback on \(audioURL.lastPathComponent)")
                    audioPlayer.stopPlayback()
                }, label: {
                    Image(systemName: "stop.fill")
                        .imageScale(.large)
                })
            }
        }
    }
    

}

struct RecordingsList_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsList(audioRecorder: RecordingEngine())
    }
}
