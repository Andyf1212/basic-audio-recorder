import Foundation
import Combine

class mFileManager: ObservableObject {
    let objectWillChange = PassthroughSubject<mFileManager, Never> ()
    var recordings = [Recording]()
    var toggles = [Bool]()
    
    var urlSelected: URL!
    
    init() {
        fetchRecordings()
    }
    
    func fetchRecordings() {
        recordings.removeAll()
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        for audio in directoryContents {
            let recording = Recording(fileURL: audio, createdAt: getCreationDate(for: audio))
            recordings.append(recording)
            toggles.append(false)
        }
        recordings.sort(by: {$0.createdAt.compare($1.createdAt) == .orderedAscending})
        objectWillChange.send(self)
    }
    
    func deleteRecording(urlsToDelete: [URL]) {
        for url in urlsToDelete {
            print(url)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("Could not delete file \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        fetchRecordings()
    }
    
    func getIndex(url: URL) -> Int {
        var index = 0
        for url_a in self.recordings {
            if url == url_a.fileURL {
                return index
            }
            index += 1
        }
        return -1
    }
    
    func renameRecording(srcUrl: URL, newName: String) {
        if newName == "" {
            // don't rename the file if no input is given
            return
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
        
        fetchRecordings()
    }
    
    func toggleProcessing(urlToToggle: URL) {
        // disable current toggle
        for i in 0...toggles.count {
            if toggles[i] {
                toggles[i] = false
            }
        }
        
        // update next toggle for url
        for i in 0...recordings.count {
            if urlToToggle == recordings[i].fileURL {
                toggles[i].toggle()
            }
        }
    }
}
