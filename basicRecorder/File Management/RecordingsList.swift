

import SwiftUI

struct RecordingsList: View {
    
    @ObservedObject var fileManager: mFileManager
    
    var body: some View {
        List {
            ForEach(fileManager.recordings, id: \.createdAt) {recording in
                RecordingRow(audioURL: recording.fileURL)
            }
            .onDelete(perform: delete)
        }
    }
    
    func delete (at offsets: IndexSet) {
        var urlsToDelete = [URL]()
        for index in offsets {
            urlsToDelete.append(fileManager.recordings[index].fileURL)
        }
        fileManager.deleteRecording(urlsToDelete: urlsToDelete)
    }
}

struct RecordingRow: View {
    
    var audioURL: URL
    
    @ObservedObject var audioPlayer = PlayEngine()
    
    var body: some View {
        HStack {
            Text("\(audioURL.lastPathComponent)")
            Spacer()
            if audioPlayer.state == .playing {
                Button(action: {
                    print("playback stop button")
                    audioPlayer.stopPlayback()
                }, label: {
                    Image(systemName: "stop.fill")
                })
            } else {
                Button(action: {
                    print("playback start button")
                    audioPlayer.startPlayback(fileURL: audioURL)
                }, label: {
                    Image(systemName: "play.circle")
                })
            }
        }
    }
    

}

struct RecordingsList_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsList(fileManager: mFileManager())
    }
}
