// MusicPlayerViewModel.swift

import Foundation
import WidgetKit
import AVFoundation
import Combine
import SwiftUI
import MediaPlayer

// MARK: - EQ Preset

enum EQPreset: String, CaseIterable, Identifiable {
    case flat        = "Flat"
    case acoustic    = "Acoustic"
    case bassBoost   = "Bass Boost"
    case treble      = "Treble"
    case rock        = "Rock"
    case pop         = "Pop"
    case classical   = "Classical"
    case jazz        = "Jazz"
    case electronic  = "Electronic"
    case vocal       = "Vocal"

    var id: String { rawValue }

    var gains: [Float] {
        switch self {
        case .flat:       return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .acoustic:   return [4, 3, 2, 1, 0, 1, 2, 3, 4, 4]
        case .bassBoost:  return [8, 7, 6, 4, 2, 0, 0, 0, 0, 0]
        case .treble:     return [0, 0, 0, 0, 0, 2, 4, 6, 7, 8]
        case .rock:       return [5, 4, 3, 2, 1, 0, 1, 2, 3, 4]
        case .pop:        return [3, 2, 1, 0, 1, 2, 3, 4, 5, 5]
        case .classical:  return [2, 3, 4, 5, 5, 4, 3, 2, 1, 0]
        case .jazz:       return [3, 4, 5, 4, 3, 2, 1, 1, 2, 3]
        case .electronic: return [6, 5, 4, 3, 2, 0, 1, 2, 4, 6]
        case .vocal:      return [2, 2, 1, 1, 2, 4, 6, 5, 4, 3]
        }
    }

    var icon: String {
        switch self {
        case .flat:       return "minus"
        case .acoustic:   return "guitars"
        case .bassBoost:  return "waveform.path"
        case .treble:     return "sparkles"
        case .rock:       return "bolt.fill"
        case .pop:        return "star.fill"
        case .classical:  return "music.note.list"
        case .jazz:       return "music.mic"
        case .electronic: return "cpu"
        case .vocal:      return "mic.fill"
        }
    }
}

// MARK: - Repeat Mode

enum RepeatMode: String, CaseIterable {
    case none, all, one

    var icon: String {
        switch self {
        case .none, .all: return "repeat"
        case .one:        return "repeat.1"
        }
    }

    var isActive: Bool { self != .none }

    mutating func cycle() {
        switch self {
        case .none: self = .all
        case .all:  self = .one
        case .one:  self = .none
        }
    }
}

// MARK: - MusicPlayerViewModel

@MainActor
class MusicPlayerViewModel: NSObject, ObservableObject {

    // MARK: Published state
    @Published var currentSong: Song?
    @Published var isPlaying         = false
    @Published var currentTime: TimeInterval = 0
    @Published var songs: [Song]     = []
    @Published var playlists: [Playlist] = []
    @Published var selectedSongForPlaylist: Song?
    @Published var isShuffleEnabled  = false
    @Published var repeatMode: RepeatMode = .none

    // EQ state
    @Published var eqEnabled         = true
    @Published var eqGains: [Float]  = Array(repeating: 0, count: 10)
    @Published var eqPreset: EQPreset = .flat

    // Sleep timer
    @Published var sleepTimerActive  = false
    @Published var sleepTimerEndTime: Date?

    // MARK: Private — Audio Engine
    private let engine     = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let eqNode     = AVAudioUnitEQ(numberOfBands: 10)

    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var shuffleHistory: [UUID] = []
    private var fileStartFrame: AVAudioFramePosition = 0
    private var isSeeking    = false
    private var currentSongID: UUID?

    // ✅ Generation counter — invalidates stale completion handlers on seek or song change
    private var seekGeneration: Int = 0

    // MARK: Persistence keys
    private let songsKey     = "Auralix_Songs"
    private let playlistsKey = "Auralix_Playlists"
    private let appGroupID   = "group.com.omaraguil.auralix"

    private let eqFrequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

    // MARK: - Init

    override init() {
        super.init()
        setupAudioSession()
        setupEngine()
        loadSongs()
        loadPlaylists()
        if playlists.isEmpty {
            createPlaylist(name: "Liked Songs")
            createPlaylist(name: "Favorites")
            createPlaylist(name: "Chill Vibes")
            createPlaylist(name: "Workout")
        }
        ensureLikedPlaylistExists()
        setupRemoteCommandCenter()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began { pauseSong() }
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        for (i, freq) in eqFrequencies.enumerated() {
            let band = eqNode.bands[i]
            band.filterType = .parametric
            band.frequency  = freq
            band.bandwidth  = 1.0
            band.gain       = 0
            band.bypass     = false
        }

        engine.attach(playerNode)
        engine.attach(eqNode)
        engine.connect(playerNode, to: eqNode,               format: nil)
        engine.connect(eqNode,     to: engine.mainMixerNode, format: nil)

        engine.prepare()
        do {
            try engine.start()
            print("✅ AVAudioEngine started")
        } catch {
            print("❌ Engine start error: \(error)")
        }
    }

    // MARK: - EQ

    func setEQGain(_ gain: Float, at index: Int) {
        guard index < eqGains.count else { return }
        eqGains[index] = gain
        eqNode.bands[index].gain = eqEnabled ? gain : 0
    }

    func applyEQPreset(_ preset: EQPreset) {
        eqPreset = preset
        for (i, g) in preset.gains.enumerated() { setEQGain(g, at: i) }
    }

    func setEQEnabled(_ on: Bool) {
        eqEnabled = on
        for i in 0..<eqGains.count { eqNode.bands[i].gain = on ? eqGains[i] : 0 }
    }

    func resetEQ() {
        eqGains  = Array(repeating: 0, count: 10)
        eqPreset = .flat
        for i in 0..<eqNode.bands.count { eqNode.bands[i].gain = 0 }
    }

    // MARK: - Playback

    func playSong(_ song: Song) {
        if playerNode.isPlaying { playerNode.stop() }

        // ✅ Bump generation — any completion scheduled before this point is now stale
        seekGeneration += 1
        let myGeneration = seekGeneration

        currentSong    = song
        currentSongID  = song.id
        currentTime    = 0
        fileStartFrame = 0
        isSeeking      = false
        shuffleHistory.append(song.id)

        do {
            let file = try AVAudioFile(forReading: song.fileURL)
            audioFile = file

            playerNode.scheduleFile(file, at: nil) { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    // ✅ Discard if a seek or song change happened after we scheduled
                    guard self.seekGeneration == myGeneration else { return }
                    self.songDidFinish()
                }
            }

            playerNode.play()
            isPlaying = true
            startTimer()
            updateNowPlayingInfo()
            print("✅ Playing: \(song.title)")
        } catch {
            print("❌ Cannot play: \(error)")
            isPlaying = false
            audioFile = nil
        }
    }

    private func songDidFinish() {
        currentTime = 0
        isPlaying   = false
        stopTimer()
        nextSong()
    }

    func pauseSong() {
        guard isPlaying else { return }
        playerNode.pause()
        isPlaying = false
        stopTimer()
        updateNowPlayingInfo()
    }

    func resumeSong() {
        guard !isPlaying else { return }
        if audioFile == nil, let song = currentSong {
            playSong(song)
            return
        }
        playerNode.play()
        isPlaying = true
        startTimer()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        isPlaying ? pauseSong() : resumeSong()
    }

    // MARK: - Seek ✅ fully fixed

    func seek(to time: TimeInterval) {
        guard let file = audioFile, let song = currentSong else { return }

        let sampleRate      = file.processingFormat.sampleRate
        let totalFrames     = file.length
        let targetFrame     = AVAudioFramePosition(time * sampleRate)
        let clampedFrame    = max(0, min(targetFrame, totalFrames - 1))
        let framesRemaining = AVAudioFrameCount(totalFrames - clampedFrame)
        guard framesRemaining > 0 else { return }

        let wasPlaying = isPlaying

        // ✅ Bump generation FIRST — kills the old scheduleFile/scheduleSegment completion
        seekGeneration += 1
        let myGeneration = seekGeneration

        isSeeking = true
        playerNode.stop()   // fires old completion, but generation guard ignores it

        playerNode.scheduleSegment(
            file,
            startingFrame: clampedFrame,
            frameCount:    framesRemaining,
            at:            nil
        ) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                // ✅ Only finish if no further seek happened
                guard self.seekGeneration == myGeneration else { return }
                self.songDidFinish()
            }
        }

        fileStartFrame = clampedFrame
        currentTime    = time           // single authoritative write

        if wasPlaying {
            playerNode.play()
            isPlaying = true
        }

        // ✅ Released AFTER play() so timer never reads a mid-seek state
        isSeeking = false
        updateNowPlayingInfo()
    }

    // MARK: - Next / Previous

    func nextSong() {
        guard !songs.isEmpty else { return }

        if isShuffleEnabled, songs.count > 1 {
            var idx: Int
            repeat { idx = Int.random(in: 0..<songs.count) }
            while songs[idx].id == currentSong?.id
            playSong(songs[idx])
            return
        }

        if repeatMode == .one, let song = currentSong {
            playSong(song)
            return
        }

        guard let current = currentSong,
              let index   = songs.firstIndex(where: { $0.id == current.id }) else {
            if !songs.isEmpty { playSong(songs[0]) }
            return
        }

        let next = index + 1
        if next >= songs.count {
            if repeatMode == .all {
                playSong(songs[0])
            } else {
                playerNode.stop()
                stopTimer()
                isPlaying   = false
                currentTime = 0
                updateNowPlayingInfo()
            }
        } else {
            playSong(songs[next])
        }
    }

    func previousSong() {
        if currentTime > 3 { seek(to: 0); return }
        guard !songs.isEmpty else { return }

        if isShuffleEnabled,
           shuffleHistory.count >= 2,
           let previousID = shuffleHistory.dropLast().last,
           let song = songs.first(where: { $0.id == previousID }) {
            shuffleHistory.removeLast()
            playSong(song)
            return
        }

        guard let current = currentSong,
              let index   = songs.firstIndex(where: { $0.id == current.id }) else { return }

        let prev = index > 0 ? index - 1 : songs.count - 1
        playSong(songs[prev])
    }

    // MARK: - Timer (single source of truth)

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, !self.isSeeking else { return }
            Task { @MainActor in
                let newTime = self.currentPlayerTime
                if abs(self.currentTime - newTime) > 0.01 {
                    self.currentTime = newTime
                }
                if Int(self.currentTime * 10) % 10 == 0 {
                    self.updateNowPlayingInfo()
                }
                self.checkSleepTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private var currentPlayerTime: TimeInterval {
        guard let file     = audioFile,
              let nodeTime = playerNode.lastRenderTime,
              let playTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return currentTime }

        let sampleRate   = file.processingFormat.sampleRate
        let playedFrames = Double(fileStartFrame) + Double(playTime.sampleTime)
        let computed     = playedFrames / sampleRate
        return min(max(computed, 0), duration)
    }

    // MARK: - Computed

    var duration: TimeInterval {
        guard let file = audioFile else { return currentSong?.duration ?? 0 }
        let d = Double(file.length) / file.processingFormat.sampleRate
        return d.isFinite ? d : 0
    }

    var progress: Double { duration > 0 ? min(currentTime / duration, 1) : 0 }

    func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, !t.isNaN, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: - Sleep Timer

    func startSleepTimer(minutes: Int) {
        sleepTimerEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepTimerActive  = true
    }

    func cancelSleepTimer() {
        sleepTimerActive  = false
        sleepTimerEndTime = nil
    }

    private func checkSleepTimer() {
        guard sleepTimerActive, let endTime = sleepTimerEndTime else { return }
        if Date() >= endTime {
            pauseSong()
            sleepTimerActive  = false
            sleepTimerEndTime = nil
        }
    }

    var timeRemainingInSleepTimer: TimeInterval? {
        guard sleepTimerActive, let endTime = sleepTimerEndTime else { return nil }
        return max(0, endTime.timeIntervalSince(Date()))
    }

    // MARK: - Widget

    private func updateWidgetData() {
        guard let ud = UserDefaults(suiteName: appGroupID) else { return }
        ud.set(currentSong?.title ?? "Not Playing", forKey: "widget_title")
        ud.set(currentSong?.artist ?? "—",          forKey: "widget_artist")
        ud.set(isPlaying,                            forKey: "widget_isPlaying")
        ud.set(currentSong?.artworkData,             forKey: "widget_artwork")
        ud.set(progress,                             forKey: "widget_progress")
        ud.set(formatTime(currentTime),              forKey: "widget_currentTime")
        ud.set(formatTime(duration),                 forKey: "widget_duration")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            updateWidgetData()
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle:                    song.title,
            MPMediaItemPropertyArtist:                   song.artist,
            MPMediaItemPropertyAlbumTitle:               song.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration:         duration,
            MPNowPlayingInfoPropertyPlaybackRate:        isPlaying ? 1.0 : 0.0
        ]

        if let data = song.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        updateWidgetData()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommandCenter() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget            { [weak self] _ in Task { @MainActor in self?.resumeSong()      }; return .success }
        cc.pauseCommand.addTarget           { [weak self] _ in Task { @MainActor in self?.pauseSong()       }; return .success }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.togglePlayPause() }; return .success }
        cc.nextTrackCommand.addTarget       { [weak self] _ in Task { @MainActor in self?.nextSong()        }; return .success }
        cc.previousTrackCommand.addTarget   { [weak self] _ in Task { @MainActor in self?.previousSong()    }; return .success }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: e.positionTime) }
            return .success
        }
    }

    // MARK: - Songs

    func saveSongs() {
        if let encoded = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(encoded, forKey: songsKey)
        }
    }

    func loadSongs() {
        guard let data = UserDefaults.standard.data(forKey: songsKey),
              let saved = try? JSONDecoder().decode([Song].self, from: data) else {
            songs = []; return
        }
        songs = saved
    }

    func addSong(_ song: Song) {
        songs.append(song)
        saveSongs()
    }

    func deleteSong(_ song: Song) {
        if currentSong?.id == song.id {
            playerNode.stop()
            currentSong = nil
            audioFile   = nil
            currentTime = 0
            isPlaying   = false
            updateNowPlayingInfo()
        }
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            try? FileManager.default.removeItem(at: song.fileURL)
            songs.remove(at: index)
            saveSongs()
        }
        for i in playlists.indices { playlists[i].removeSong(song.id) }
        savePlaylists()
    }

    func toggleLike(for song: Song) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        songs[index].isLiked.toggle()
        saveSongs()
        if currentSong?.id == song.id { currentSong = songs[index] }
        if let liked = getLikedPlaylist() {
            songs[index].isLiked
                ? addSongToPlaylist(song: songs[index], playlist: liked)
                : removeSongFromPlaylist(song: songs[index], playlist: liked)
        }
    }

    // MARK: - Playlists

    func ensureLikedPlaylistExists() {
        guard !playlists.contains(where: { $0.name == "Liked Songs" }) else { return }
        playlists.insert(Playlist(name: "Liked Songs", artworkName: "heart.fill"), at: 0)
        savePlaylists()
    }

    func getLikedPlaylist() -> Playlist? { playlists.first { $0.name == "Liked Songs" } }

    func savePlaylists() {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: playlistsKey)
        }
    }

    func loadPlaylists() {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey),
              let saved = try? JSONDecoder().decode([Playlist].self, from: data) else {
            playlists = []; return
        }
        playlists = saved
    }

    func createPlaylist(name: String) {
        playlists.append(Playlist(name: name))
        savePlaylists()
    }

    func deletePlaylist(_ playlist: Playlist) {
        guard playlist.name != "Liked Songs" else { return }
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }

    func deletePlaylist(at offsets: IndexSet) {
        let filtered = offsets.filter { playlists[$0].name != "Liked Songs" }
        playlists.remove(atOffsets: IndexSet(filtered))
        savePlaylists()
    }

    func addSongToPlaylist(song: Song, playlist: Playlist) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[i].addSong(song.id)
        savePlaylists()
    }

    func removeSongFromPlaylist(song: Song, playlist: Playlist) {
        guard let i = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[i].removeSong(song.id)
        savePlaylists()
    }

    func isSongInPlaylist(song: Song, playlist: Playlist) -> Bool {
        playlist.containsSong(song.id)
    }

    func songs(in playlist: Playlist) -> [Song] {
        playlist.songIDs.compactMap { id in songs.first { $0.id == id } }
    }
}
