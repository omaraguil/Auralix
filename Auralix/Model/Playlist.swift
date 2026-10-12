import Foundation

struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var songIDs: [UUID]
    var artworkName: String
    
    init(id: UUID = UUID(), name: String, songIDs: [UUID] = [], artworkName: String = "music.note.list") {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.artworkName = artworkName
    }
    
    mutating func addSong(_ songID: UUID) {
        if !songIDs.contains(songID) {
            songIDs.append(songID)
        }
    }
    
    mutating func removeSong(_ songID: UUID) {
        songIDs.removeAll { $0 == songID }
    }
    
    func containsSong(_ songID: UUID) -> Bool {
        songIDs.contains(songID)
    }
}
