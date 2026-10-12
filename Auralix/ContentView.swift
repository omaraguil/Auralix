import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()

    var body: some View {
        TabView {
            PlayerView(viewModel: viewModel)
                .tabItem {
                    Label("Player", systemImage: "play.circle.fill")
                }

            LibraryView(viewModel: viewModel)
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }

            PlaylistView(viewModel: viewModel)
                .tabItem {
                    Label("Playlists", systemImage: "rectangle.stack.fill")
                }
        }
        .tint(.purple)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.05, green: 0.02, blue: 0.12, alpha: 0.96)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
