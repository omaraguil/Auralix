import Foundation
import Combine
import SwiftUI

@MainActor
class YouTubeDownloadService: ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0
    @Published var statusMessage = ""
    @Published var downloadedSong: Song?
    
    // YOUR BACKEND URL
    private let baseURL = "https://auralix-api.onrender.com"
    
    // Token from .env file (DEVELOPMENT=true)
    private let authToken = "when_the_pig_fly"
    
    func downloadAudio(from urlString: String) async throws -> Song? {
        guard !urlString.isEmpty else {
            throw DownloadError.invalidURL
        }
        
        await MainActor.run {
            isDownloading = true
            progress = 0
            statusMessage = "Connecting to server..."
        }
        
        do {
            guard let url = URL(string: "\(baseURL)/download") else {
                throw DownloadError.apiError
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = ["url": urlString]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            await MainActor.run {
                statusMessage = "Requesting download..."
                progress = 0.2
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DownloadError.apiError
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 403 {
                print("Authentication failed - token may be incorrect")
                throw DownloadError.authError
            }
            
            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = errorJson["detail"] as? String {
                    print("Server error: \(errorMsg)")
                }
                throw DownloadError.apiError
            }
            
            await MainActor.run {
                statusMessage = "Processing response..."
                progress = 0.4
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Response: \(json ?? [:])")
            
            guard let downloadLink = json?["download_link"] as? String,
                  let filename = json?["filename"] as? String else {
                print("Missing download_link or filename in response")
                throw DownloadError.noAudioFound
            }
            
            let title = filename.replacingOccurrences(of: ".mp3", with: "").replacingOccurrences(of: "_", with: " ")
            let artist = "YouTube Download"
            
            await MainActor.run {
                statusMessage = "Downloading audio file..."
                progress = 0.6
            }
            
            let fullDownloadURL = "\(baseURL)\(downloadLink)"
            print("Download URL: \(fullDownloadURL)")
            
            guard let downloadURL = URL(string: fullDownloadURL) else {
                throw DownloadError.noAudioFound
            }
            
            let (fileURL, _) = try await URLSession.shared.download(from: downloadURL)
            
            await MainActor.run {
                statusMessage = "Saving to library..."
                progress = 0.8
            }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(filename)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
            
            await MainActor.run {
                progress = 0.9
                statusMessage = "Creating song entry..."
            }
            
            var artworkData: Data? = nil
            if let thumbnail = json?["thumbnail"] as? String,
               let thumbnailURL = URL(string: thumbnail) {
                do {
                    let (thumbData, _) = try await URLSession.shared.data(from: thumbnailURL)
                    artworkData = thumbData
                } catch {
                    print("Could not download thumbnail")
                }
            }
            
            let song = Song(
                title: title,
                artist: artist,
                album: "YouTube Download",
                fileName: filename,
                fileURL: destinationURL,
                artworkData: artworkData,
                duration: 0
            )
            
            await MainActor.run {
                downloadedSong = song
                isDownloading = false
                progress = 1.0
                statusMessage = "Download complete!"
            }
            
            return song
            
        } catch {
            print("Download error details: \(error)")
            await MainActor.run {
                statusMessage = "Error: \(error.localizedDescription)"
                isDownloading = false
                progress = 0
            }
            throw error
        }
    }
    
    enum DownloadError: LocalizedError {
        case invalidURL
        case noAudioFound
        case apiError
        case authError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid YouTube URL"
            case .noAudioFound:
                return "No audio found for this video"
            case .apiError:
                return "Server error. Please try again"
            case .authError:
                return "Authentication failed"
            }
        }
    }
}
