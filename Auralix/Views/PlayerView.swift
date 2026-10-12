// PlayerView.swift

import SwiftUI
import Combine
import AVFoundation

struct PlayerView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel

    // Sheet toggles
    @State private var showEqualizer     = false
    @State private var showSleepTimer    = false
    @State private var showAddToPlaylist = false

    // Slider — nil = not dragging, VM drives display
    @State private var isDraggingSlider  = false
    @State private var dragProgress: Double? = nil

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Artwork

    var artworkImage: some View {
        Group {
            if let data = viewModel.currentSong?.artworkData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.18, blue: 0.58),
                            Color(red: 0.12, green: 0.06, blue: 0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background — blurred artwork
            GeometryReader { geo in
                ZStack {
                    if let data = viewModel.currentSong?.artworkData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .blur(radius: 60)
                            .scaleEffect(1.3)
                            .opacity(0.35)
                    }
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.02, blue: 0.14).opacity(0.92),
                            Color(red: 0.04, green: 0.01, blue: 0.10).opacity(0.97)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            }

            // Content
            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                artworkSection
                    .padding(.horizontal, 32)
                Spacer(minLength: 0)
                songInfoSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
                progressSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                controlsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
                bottomBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showEqualizer)     { EqualizerView(viewModel: viewModel) }
        .sheet(isPresented: $showSleepTimer)    { SleepTimerView(viewModel: viewModel, isPresented: $showSleepTimer) }
        .sheet(isPresented: $showAddToPlaylist) {
            if let song = viewModel.currentSong {
                AddToPlaylistSheet(viewModel: viewModel, song: song, isPresented: $showAddToPlaylist)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("NOW PLAYING")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            if viewModel.sleepTimerActive,
               let remaining = viewModel.timeRemainingInSleepTimer {
                HStack(spacing: 4) {
                    Image(systemName: "moon.fill").font(.system(size: 10))
                    Text(formatShortTime(remaining))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.purple.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.purple.opacity(0.15)))
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Artwork Section

    private var artworkSection: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(viewModel.isPlaying ? 0.45 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius:   size * 0.7
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .animation(.easeInOut(duration: 1.2), value: viewModel.isPlaying)

                artworkImage
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: .black.opacity(0.5),
                        radius: viewModel.isPlaying ? 32 : 16,
                        y:      viewModel.isPlaying ? 20 : 10
                    )
                    .scaleEffect(viewModel.isPlaying ? 1.0 : 0.92)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isPlaying)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Song Info

    private var songInfoSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentSong?.title ?? "No Song Selected")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(viewModel.currentSong?.artist ?? "—")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                if let song = viewModel.currentSong { viewModel.toggleLike(for: song) }
            } label: {
                Image(systemName: viewModel.currentSong?.isLiked == true ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.currentSong?.isLiked == true ? .pink : .white.opacity(0.45))
                    .scaleEffect(viewModel.currentSong?.isLiked == true ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.currentSong?.isLiked)
            }
            .disabled(viewModel.currentSong == nil)
        }
    }

    // MARK: - Progress Slider ✅ fixed

    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                // nil dragProgress → follow VM; non-nil → follow finger
                let displayProgress = dragProgress ?? viewModel.progress

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: isDraggingSlider ? 6 : 4)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width:  max(0, displayProgress * width),
                            height: isDraggingSlider ? 6 : 4
                        )

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(
                            width:  isDraggingSlider ? 18 : 12,
                            height: isDraggingSlider ? 18 : 12
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3)
                        .offset(x: max(0, displayProgress * width - (isDraggingSlider ? 9 : 6)))
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingSlider = true
                            // ✅ Only local state — VM is never touched while dragging
                            dragProgress = max(0, min(1, value.location.x / width))
                        }
                        .onEnded { value in
                            let pct = max(0, min(1, value.location.x / width))
                            // ✅ Single seek call on finger-lift
                            viewModel.seek(to: pct * viewModel.duration)
                            // ✅ Hand display back to VM immediately
                            dragProgress     = nil
                            isDraggingSlider = false
                        }
                )
            }
            .frame(height: 24)

            // Time labels
            HStack {
                let displayTime: TimeInterval = isDraggingSlider
                    ? (dragProgress ?? viewModel.progress) * viewModel.duration
                    : viewModel.currentTime

                Text(viewModel.formatTime(displayTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                Text(viewModel.formatTime(viewModel.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: 0) {
            Spacer()

            Button { viewModel.previousSong() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.85))
            }
            .disabled(viewModel.songs.isEmpty)

            Spacer()

            Button { viewModel.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                        .shadow(color: .purple.opacity(0.4), radius: 16, y: 6)

                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.04, blue: 0.22))
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
            }
            .scaleEffect(viewModel.isPlaying ? 1.0 : 0.97)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isPlaying)

            Spacer()

            Button { viewModel.nextSong() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.85))
            }
            .disabled(viewModel.songs.isEmpty)

            Spacer()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button { viewModel.isShuffleEnabled.toggle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.isShuffleEnabled ? .purple : .white.opacity(0.4))
                    .overlay(alignment: .topTrailing) {
                        if viewModel.isShuffleEnabled {
                            Circle().fill(Color.purple).frame(width: 5, height: 5).offset(x: 2, y: -2)
                        }
                    }
            }

            Spacer()

            Button { viewModel.repeatMode.cycle() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: viewModel.repeatMode.icon)
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.repeatMode.isActive ? .purple : .white.opacity(0.4))

                    if viewModel.repeatMode == .one {
                        Text("1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 12, height: 12)
                            .background(Circle().fill(Color.purple))
                            .offset(x: 6, y: -6)
                    } else if viewModel.repeatMode == .all {
                        Circle().fill(Color.purple).frame(width: 5, height: 5).offset(x: 2, y: -2)
                    }
                }
            }

            Spacer()

            Button { showEqualizer = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Button { showSleepTimer = true } label: {
                Image(systemName: viewModel.sleepTimerActive ? "moon.fill" : "moon")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.sleepTimerActive ? .purple : .white.opacity(0.4))
            }

            Spacer()

            Button {
                if viewModel.currentSong != nil { showAddToPlaylist = true }
            } label: {
                Image(systemName: "text.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.4))
            }
            .disabled(viewModel.currentSong == nil)
        }
    }

    // MARK: - Helpers

    private func formatShortTime(_ time: TimeInterval) -> String {
        let t = max(0, time)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Add To Playlist Sheet

struct AddToPlaylistSheet: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    let song: Song
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.03, blue: 0.16).ignoresSafeArea()

                if viewModel.playlists.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                        Text("No playlists yet")
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    List {
                        ForEach(viewModel.playlists) { playlist in
                            Button {
                                viewModel.isSongInPlaylist(song: song, playlist: playlist)
                                    ? viewModel.removeSongFromPlaylist(song: song, playlist: playlist)
                                    : viewModel.addSongToPlaylist(song: song, playlist: playlist)
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: playlist.artworkName)
                                            .font(.system(size: 16))
                                            .foregroundColor(.purple)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.name)
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .medium))
                                        Text("\(viewModel.songs(in: playlist).count) songs")
                                            .foregroundColor(.white.opacity(0.4))
                                            .font(.system(size: 12))
                                    }

                                    Spacer()

                                    if viewModel.isSongInPlaylist(song: song, playlist: playlist) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.purple)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    PlayerView(viewModel: MusicPlayerViewModel())
        .preferredColorScheme(.dark)
}
