

import SwiftUI
import AVFAudio
import UniformTypeIdentifiers

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
    @State var fileName: String!
    
    @ObservedObject var audioPlayer = PlayEngine()
    // @ObservedObject var fileManager = mFileManager()
    
    @State var showAlert = false
    
    var body: some View {
            HStack {
                Text("\(audioURL.lastPathComponent)")
                Spacer()
                Button(action: {
                    showAlert.toggle()
                    print("Toggled exporter")
                }, label: {
                    Image(systemName:"square.and.arrow.up")
                })
                .alert(isPresented: $showAlert,
                       TextAlert(title: "Export", message: "Enter file name") { result in
                    if let text = result {
                        // accepted text
                        print(text)
                    } else {
                        // cancelled
                    }
                })
    
                .buttonStyle(BorderlessButtonStyle())
                Spacer()
                if audioPlayer.state == .playing {
                    Button(action: {
                        print("playback stop button")
                        audioPlayer.stopPlayback()
                    }, label: {
                        Image(systemName: "stop.fill")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                } else {
                    Button(action: {
                        print("playback start button")
                        audioPlayer.startPlayback(fileURL: audioURL)
                    }, label: {
                        Image(systemName: "play.circle")
                    })
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
    }
    
    // functions
    func exportFile(audioURL: URL, newName: String = "") {
        do {
            let myManager = FileManager()
            
            // set up export
            let pathComponents: [String] = audioURL.pathComponents
            var currentFileName = pathComponents.last
            var exportName = newName
            if exportName != "" {
                // check to see if file extension is still there
                if exportName.suffix(4) != ".caf" {
                    exportName.append(".caf")
                }
                
            } else {
                exportName = currentFileName ?? "default.caf"
            }
            
            // check for myRecordings directory in /Documents/
            
            try myManager.moveItem(at: audioURL, to: audioURL)
        } catch {
            print("Error exporting file \(audioURL.absoluteString): \(error.localizedDescription)")
        }
        
        print("Exported \(newName)")
    }

}

struct Doc: FileDocument {
    var url: String
    static var readableContentTypes: [UTType]{[.audio]}
    
    init (url: String) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        url = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let file = try FileWrapper(url: URL(fileURLWithPath: url), options: .immediate)
        return file
    }
}

struct RecordingsList_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsList(fileManager: mFileManager())
    }
}
