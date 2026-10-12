//import SwiftUI
//
//struct AddToPlaylistSheet: View {
//    @ObservedObject var viewModel: MusicPlayerViewModel
//    let song: Song?
//    @Binding var isPresented: Bool
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                LinearGradient(colors: [Color(red: 0.08, green: 0.04, blue: 0.18), Color(red: 0.12, green: 0.08, blue: 0.22)], startPoint: .top, endPoint: .bottom)
//                    .ignoresSafeArea()
//                
//                List {
//                    ForEach(viewModel.playlists) { playlist in
//                        Button {
//                            guard let song = song else { return }
//                            if viewModel.isSongInPlaylist(song: song, playlist: playlist) {
//                                viewModel.removeSongFromPlaylist(song: song, playlist: playlist)
//                            } else {
//                                viewModel.addSongToPlaylist(song: song, playlist: playlist)
//                            }
//                            isPresented = false
//                        } label: {
//                            HStack {
//                                Image(systemName: "rectangle.stack.fill").foregroundColor(.purple).font(.title3)
//                                Text(playlist.name).font(.system(size: 16, weight: .medium, design: .rounded)).foregroundColor(.white)
//                                Spacer()
//                                if let song = song, viewModel.isSongInPlaylist(song: song, playlist: playlist) {
//                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
//                                } else {
//                                    Image(systemName: "plus.circle").foregroundColor(.white.opacity(0.5))
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                        .buttonStyle(.plain)
//                        .listRowBackground(Color.clear)
//                    }
//                }
//                .scrollContentBackground(.hidden)
//                .background(Color.clear)
//            }
//            .navigationTitle("Add to Playlist")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { isPresented = false }.foregroundColor(.purple) } }
//            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//        }
//        .presentationDetents([.medium])
//        .presentationDragIndicator(.visible)
//    }
//}
