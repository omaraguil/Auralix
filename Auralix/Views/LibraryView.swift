import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @State private var showingFileImporter = false
    @State private var showingDownload = false
    @State private var searchText = ""
    @State private var selectedSong: Song?
    @State private var showingPlaylistSheet = false
    @State private var songToDelete: Song?
    @State private var showingDeleteAlert = false

    private let gradient = LinearGradient(
        colors: [Color(red: 0.06, green: 0.02, blue: 0.14), Color(red: 0.10, green: 0.05, blue: 0.20)],
        startPoint: .top,
        endPoint: .bottom
    )

    var filteredSongs: [Song] {
        if searchText.isEmpty { return viewModel.songs }
        return viewModel.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                gradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Premium custom header ──────────────────────────────
                    premiumHeader

                    // ── Search bar ─────────────────────────────────────────
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    // ── Content ────────────────────────────────────────────
                    if viewModel.songs.isEmpty {
                        emptyState
                    } else {
                        songList
                    }
                }
            }
            // Hide the default navigation bar entirely
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [
                    UTType.audio,
                    UTType.mp3,
                    UTType(filenameExtension: "m4a") ?? .audio,
                    UTType(filenameExtension: "aac") ?? .audio,
                    UTType(filenameExtension: "wav") ?? .audio,
                    UTType(filenameExtension: "flac") ?? .audio
                ],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        if let song = Song.importFromURL(url) {
                            viewModel.addSong(song)
                        }
                    }
                case .failure(let error):
                    print("Import error: \(error)")
                }
            }
            .alert("Delete Song", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let song = songToDelete {
                        viewModel.deleteSong(song)
                        songToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(songToDelete?.title ?? "this song")\"?")
            }
            .sheet(isPresented: $showingPlaylistSheet) {
                if let song = selectedSong {
                    AddToPlaylistSheet(
                        viewModel: viewModel,
                        song: song,
                        isPresented: $showingPlaylistSheet
                    )
                }
            }
            .sheet(isPresented: $showingDownload) {
                YouTubeDownloadView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Premium Header
    private var premiumHeader: some View {
        HStack(alignment: .center) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(viewModel.songs.count) song\(viewModel.songs.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            // Download button
            Button {
                showingDownload = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Download")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                )
            }

            // Add button — premium pill
            Button {
                showingFileImporter = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color(red: 0.5, green: 0.2, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.45), radius: 8, y: 3)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56) // clears status bar / safe area
        .padding(.bottom, 4)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))

            TextField("Search songs or artists…", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
                .submitLabel(.search)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "music.note.list")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.purple.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("No Songs Yet")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add music from your files or download\na track using the buttons above.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Quick-action buttons in empty state
            HStack(spacing: 12) {
                Button {
                    showingDownload = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download")
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                }

                Button {
                    showingFileImporter = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Files")
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, Color(red: 0.5, green: 0.2, blue: 0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.4), radius: 8, y: 3)
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Song List
    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredSongs) { song in
                    LibrarySongCard(
                        song: song,
                        viewModel: viewModel,
                        onDelete: {
                            songToDelete = song
                            showingDeleteAlert = true
                        },
                        onAddToPlaylist: {
                            selectedSong = song
                            showingPlaylistSheet = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Library Song Card
struct LibrarySongCard: View {
    let song: Song
    @ObservedObject var viewModel: MusicPlayerViewModel
    let onDelete: () -> Void
    let onAddToPlaylist: () -> Void

    private var isCurrentSong: Bool { viewModel.currentSong?.id == song.id }

    var body: some View {
        HStack(spacing: 14) {

            // Artwork thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 52, height: 52)

                if let data = song.artworkData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.purple.opacity(0.7))
                }

                // Playing overlay on artwork
                if isCurrentSong && viewModel.isPlaying {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 52, height: 52)
                    Image(systemName: "waveform")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.purple)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                }
            }

            // Song info
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isCurrentSong ? .purple : .white)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(song.artist)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(1)

                    if song.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.pink.opacity(0.8))
                    }
                }
            }

            Spacer()

            // Duration
            Text(formatDuration(song.duration))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.30))

            // Context menu
            Menu {
                Button(action: onAddToPlaylist) {
                    Label("Add to Playlist", systemImage: "plus.square.on.square")
                }
                Button {
                    viewModel.toggleLike(for: song)
                } label: {
                    Label(
                        song.isLiked ? "Unlike" : "Like",
                        systemImage: song.isLiked ? "heart.slash" : "heart"
                    )
                }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentSong ? Color.purple.opacity(0.10) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isCurrentSong ? Color.purple.opacity(0.30) : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.playSong(song)
        }
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        guard d > 0 && d.isFinite else { return "--:--" }
        let m = Int(d) / 60
        let s = Int(d) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Playing Indicator
struct PlayingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink.opacity(0.8)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: animating ? [18.0, 24.0, 14.0][i] : [8.0, 12.0, 6.0][i])
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .frame(width: 20, height: 24)
        .onAppear { animating = true }
        .onDisappear { animating = false }
    }
}
