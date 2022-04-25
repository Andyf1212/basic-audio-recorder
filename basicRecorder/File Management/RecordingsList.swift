import SwiftUI
import AVFAudio
import UniformTypeIdentifiers

struct RecordingsList: View {
    
    @EnvironmentObject var fileManager: mFileManager
    
    @State var processing: Bool
    
    var body: some View {
        List {
            ForEach(fileManager.recordings, id: \.createdAt) {recording in
                RegisterRecordingRow(audioURL: recording.fileURL)
            }
            .onDelete(perform: delete)
        }
        .environmentObject(fileManager)
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
    @EnvironmentObject var fileManager: mFileManager
    
    @State var audioURL: URL
    @State var refresh: Bool = false
    
    @State var fileName: String? = ""
    
    @ObservedObject var audioPlayer = PlayEngine()
    // @ObservedObject var fileManager = mFileManager()
    
    @State var showAlert = false
    
    var body: some View {
            HStack {
                Text("\(audioURL.lastPathComponent)")
                    .truncationMode(.head)
                Spacer()
                
                HStack(alignment: .lastTextBaseline) {
                    Spacer()
                    Button(action: {
                        print("start url: \(audioURL.absoluteString)")
                        showAlert.toggle()
                        print("Toggled exporter")
                    }, label: {
                        Image(systemName:"square.and.pencil")
                    })
                    .alert(isPresented: $showAlert,
                           TextAlert(title: "Rename File", message: "Enter file name") { result in
                        if let text = result {
                            let success = renameFile(srcUrl: audioURL, newName: text)
                            fileManager.renameRecording(srcUrl: audioURL, newName: text)
                            self.audioURL = success
                            print(text)
                        } else {
                            // cancelled
                        }
                    })
                    
                    
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
    }
    
    // functions
    func exportFile(audioURL: URL, newName: String = "") {
        // UNFINISHED
        
//        do {
//            let myManager = FileManager()
//
//            // set up export
//            let pathComponents: [String] = audioURL.pathComponents
//            var currentFileName = pathComponents.last
//            var exportName = newName
//            if exportName != "" {
//                // check to see if file extension is still there
//                if exportName.suffix(4) != ".caf" {
//                    exportName.append(".caf")
//                }
//
//            } else {
//                exportName = currentFileName ?? "default.caf"
//            }
//
//            // check for myRecordings directory in /Documents/
//
//            try myManager.moveItem(at: audioURL, to: audioURL)
//        } catch {
//            print("Error exporting file \(audioURL.absoluteString): \(error.localizedDescription)")
//        }
//
//        print("Exported \(newName)")
    }
    
    func renameFile(srcUrl: URL, newName: String) -> URL {
        if newName == "" {
            // don't rename the file if no input is given
            return srcUrl
        }

        var url = srcUrl
        let current_file_name: String = url.lastPathComponent
        let current_extension: String = String(current_file_name.suffix(4))   // file extension, we need to match them

        var outName = newName

        // remove file extension
        if String(outName.suffix(4)).first == "." {
            // assume it's an extension
            outName = String(outName.dropLast(4))
        }

        url = url.deletingLastPathComponent()
        // check for duplicate files
        let mFileManager = FileManager()
        var contents: [String]! = ["error"]
        do {
            contents = try mFileManager.contentsOfDirectory(atPath: url.absoluteString)
        } catch {
            print("Error loading contents at specified directory \(url.absoluteString): \(error.localizedDescription)")
        }
        for path in contents {
            let current_url = URL(string: path)
            if current_url?.lastPathComponent == outName {
                let current_idx = String(outName.suffix(0))
                var idx_is_suffix = false
                var new_idx = 0
                while current_idx == String(new_idx) {
                    new_idx += 1
                    if idx_is_suffix == false {
                        idx_is_suffix = true
                    }
                }

                // if index is already a number, increment
                if idx_is_suffix {
                    outName = outName.dropLast() + String(new_idx)
                } else {
                    outName = outName + "_\(new_idx)"
                }
            }
        }

        // add file extension
        outName += current_extension

        // actually rename the file
        do {
            try mFileManager.moveItem(at: srcUrl, to: url.appendingPathComponent(outName))
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }

        return url.appendingPathComponent(outName)
    }
}

struct RegisterRecordingRow: View {
    @EnvironmentObject var player: PlaybackEngine
    @EnvironmentObject var fileManager: mFileManager
    var audioURL: URL
    
    @State var showingTextBox = false
    @State var textFieldEntry: String = ""
    @State var playing = false
    
    var body: some View {
        ZStack {
            HStack {
                // label
                Text("\(audioURL.lastPathComponent)")
                
                // rename button
                Button(action: {
                    showingTextBox = true
                }, label: {
                    Image(systemName: "square.and.pencil")
                })
                .buttonStyle(BorderedButtonStyle())
                
                // playback button
                if player.state == .stopped {
                    Button(action: {
                        player.registerURL(audioURL: audioURL)
                        playing = true
                        player.startPlayback()
                    }, label: {
                        Image(systemName: "play.fill")
                    })
                    .buttonStyle(BorderedButtonStyle())
                } else if player.state == .playing && player.srcUrl == audioURL {
                    Button(action: {
                        playing = false
                        player.stopPlayback()
                    }, label: {
                        Image(systemName: "stop.fill")
                    })
                    .buttonStyle(BorderedButtonStyle())
                }
            }
            
            if showingTextBox {
                Form {
                    TextField("Rename file.", text: $textFieldEntry, prompt: Text("Enter new file name"))
                        .disableAutocorrection(true)
                }
                .onSubmit {
                    fileManager.renameRecording(srcUrl: audioURL, newName: textFieldEntry)
                    showingTextBox = false
                }
            }
        }
        .environmentObject(player)
        .environmentObject(fileManager)
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
        RecordingsList(processing: true)
    }
}
