import SwiftUI

struct PlaylistView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @State private var showingNewPlaylist = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.08, green: 0.04, blue: 0.18), Color(red: 0.12, green: 0.08, blue: 0.22)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.playlists) { playlist in
                            PlaylistRow(playlist: playlist, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewPlaylist = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.white)
                    }
                }
            }
            .alert("New Playlist", isPresented: $showingNewPlaylist) {
                TextField("Playlist name", text: $newPlaylistName)
                Button("Create") {
                    if !newPlaylistName.isEmpty {
                        viewModel.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .overlay {
                if viewModel.playlists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.stack").font(.system(size: 50)).foregroundColor(.white.opacity(0.3))
                        Text("No Playlists").font(.title2).fontWeight(.semibold).foregroundColor(.white.opacity(0.6))
                        Text("Tap + to create your first playlist").font(.subheadline).foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    @ObservedObject var viewModel: MusicPlayerViewModel
    
    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist, viewModel: viewModel)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.purple.opacity(0.3), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    Image(systemName: playlist.artworkName)
                        .font(.system(size: 24))
                        .foregroundColor(.purple.opacity(0.7))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(playlist.songIDs.count) songs")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deletePlaylist(playlist)
            } label: {
                Label("Delete Playlist", systemImage: "trash")
            }
        }
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var viewModel: MusicPlayerViewModel
    @State private var songToRemove: Song?
    @State private var showingRemoveAlert = false
    
    var playlistSongs: [Song] {
        viewModel.songs.filter { playlist.songIDs.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.08, green: 0.04, blue: 0.18), Color(red: 0.12, green: 0.08, blue: 0.22)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(playlistSongs) { song in
                        PlaylistSongCard(
                            song: song,
                            viewModel: viewModel,
                            onRemove: {
                                songToRemove = song
                                showingRemoveAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert("Remove from Playlist", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let song = songToRemove {
                    viewModel.removeSongFromPlaylist(song: song, playlist: playlist)
                    songToRemove = nil
                }
            }
        } message: {
            Text("Remove this song from \(playlist.name)?")
        }
        .overlay {
            if playlistSongs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No Songs")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Add songs from Library using the ⋯ menu")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }
}

struct PlaylistSongCard: View {
    let song: Song
    @ObservedObject var viewModel: MusicPlayerViewModel
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 45, height: 45)
                if let data = song.artworkData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 45, height: 45)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.purple.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(song.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if song.isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }
                
                Text(song.artist)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onTapGesture {
            viewModel.playSong(song)
        }
    }
}
