import Foundation
import AVFoundation
import SwiftUI

struct Song: Identifiable, Codable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    var fileName: String
    var fileURL: URL
    var artworkData: Data?
    var duration: TimeInterval
    var isLiked: Bool = false

    init(id: UUID = UUID(), title: String, artist: String, album: String = "", fileName: String, fileURL: URL, artworkData: Data? = nil, duration: TimeInterval = 0, isLiked: Bool = false) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.fileName = fileName
        self.fileURL = fileURL
        self.artworkData = artworkData
        self.duration = duration
        self.isLiked = isLiked
    }

    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, fileName, artworkData, duration, isLiked
        case fileURLPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album) ?? ""
        fileName = try container.decode(String.self, forKey: .fileName)
        artworkData = try container.decodeIfPresent(Data.self, forKey: .artworkData)
        duration = try container.decode(Double.self, forKey: .duration)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        let path = try container.decode(String.self, forKey: .fileURLPath)
        fileURL = URL(fileURLWithPath: path)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(artworkData, forKey: .artworkData)
        try container.encode(duration, forKey: .duration)
        try container.encode(isLiked, forKey: .isLiked)
        try container.encode(fileURL.path, forKey: .fileURLPath)
    }

    // MARK: - Import (FIXED: extracts real title, artist, album, artwork from MP3/M4A metadata)
    static func importFromURL(_ url: URL) -> Song? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        // Copy file to Documents first so we have a stable local URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)

        do {
            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.copyItem(at: url, to: destinationURL)
            }
        } catch {
            print("Copy error: \(error)")
            return nil
        }

        // Read metadata from the local copy (more reliable than security-scoped URL)
        let asset = AVURLAsset(url: destinationURL)

        // FIX 1: Default title from filename (strip extension cleanly)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var artworkData: Data? = nil
        let duration = asset.duration.seconds.isNaN ? 0 : asset.duration.seconds

        // FIX 2: Extract metadata (title, artist, album, artwork) synchronously
        for item in asset.commonMetadata {
            switch item.commonKey {
            case .commonKeyTitle:
                if let value = item.stringValue, !value.isEmpty {
                    title = value
                }
            case .commonKeyArtist:
                if let value = item.stringValue, !value.isEmpty {
                    artist = value
                }
            case .commonKeyAlbumName:
                if let value = item.stringValue, !value.isEmpty {
                    album = value
                }
            case .commonKeyArtwork:
                // FIX 3: Extract artwork data — works for MP3 (ID3) and M4A (iTunes)
                if let data = item.dataValue {
                    artworkData = data
                } else if let value = item.value as? Data {
                    artworkData = value
                }
            default:
                break
            }
        }

        // FIX 4: Fallback — try iTunes-specific metadata for artwork if commonMetadata missed it
        if artworkData == nil {
            let iTunesMetadata = asset.metadata(forFormat: .iTunesMetadata)
            for item in iTunesMetadata {
                if item.commonKey == .commonKeyArtwork {
                    if let data = item.dataValue {
                        artworkData = data
                        break
                    }
                }
            }
        }

        // FIX 5: Fallback — try ID3 metadata for MP3 artwork
        if artworkData == nil {
            let id3Metadata = asset.metadata(forFormat: .id3Metadata)
            for item in id3Metadata {
                if let key = item.key as? String,
                   (key == "APIC" || key.contains("artwork") || key.contains("Artwork")),
                   let data = item.dataValue {
                    artworkData = data
                    break
                }
            }
        }

        return Song(
            title: title,
            artist: artist,
            album: album,
            fileName: url.lastPathComponent,
            fileURL: destinationURL,
            artworkData: artworkData,
            duration: duration
        )
    }
}
