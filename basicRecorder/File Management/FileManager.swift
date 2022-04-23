//
//  FileManager.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/22/22.
//

import Foundation
import Combine

class mFileManager: ObservableObject {
    let objectWillChange = PassthroughSubject<mFileManager, Never> ()
    var recordings = [Recording]()
    
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
}
