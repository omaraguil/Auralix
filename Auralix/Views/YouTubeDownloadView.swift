import SwiftUI

struct YouTubeDownloadView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @StateObject private var downloadService = YouTubeDownloadService()
    @State private var youtubeURL = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Ambient Background Base
                Color(red: 0.06, green: 0.02, blue: 0.14)
                    .ignoresSafeArea()
                
                // Ambient Radial Glows
                VStack {
                    Circle()
                        .fill(Color.purple.opacity(0.18))
                        .frame(width: 350, height: 350)
                        .blur(radius: 70)
                        .offset(y: -80)
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // Premium Header Branding Block
                        VStack(spacing: 16) {
                            ZStack {
                                // Double glass layer glow icon
                                Circle()
                                    .fill(.white.opacity(0.04))
                                    .background(Circle().fill(.ultraThinMaterial))
                                    .frame(width: 96, height: 96)
                                    .shadow(color: .purple.opacity(0.2), radius: 15, x: 0, y: 10)
                                
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.4), .pink.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                    .frame(width: 96, height: 96)
                                
                                Image(systemName: "square.and.arrow.down.on.square.fill")
                                    .font(.system(size: 34, weight: .medium))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        Color.white.opacity(0.15)
                                    )
                            }
                            
                            VStack(spacing: 6) {
                                Text("Cloud Importer")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                
                                Text("Seamlessly parse and stream your media directly")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding(.top, 28)
                        
                        // Input Field Card Group
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SOURCE MEDIA LINK")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 4)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.purple.opacity(0.7))
                                
                                TextField("Paste YouTube link here...", text: $youtubeURL)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .submitLabel(.done)
                                
                                if !youtubeURL.isEmpty {
                                    Button {
                                        youtubeURL = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                            .padding(16)
                            // Premium Glass Container Styling
                            .background(.white.opacity(0.04))
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Execution Controls and Progress Tracking Stack
                        VStack(spacing: 20) {
                            // High-End Interactive Action Button
                            Button(action: startDownload) {
                                HStack(spacing: 12) {
                                    if downloadService.isDownloading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    
                                    Text(downloadService.isDownloading ? "Extracting Tracks..." : "Fetch Audio")
                                        .font(.system(size: 16, weight: .semibold))
                                        .tracking(0.3)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, Color(red: 0.85, green: 0.3, blue: 0.65)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: (youtubeURL.isEmpty || downloadService.isDownloading) ? .clear : .purple.opacity(0.35), radius: 15, x: 0, y: 8)
                            }
                            .disabled(youtubeURL.isEmpty || downloadService.isDownloading)
                            .opacity((youtubeURL.isEmpty || downloadService.isDownloading) ? 0.55 : 1.0)
                            .animation(.easeInOut, value: youtubeURL.isEmpty)
                            
                            // Dynamic High-Fidelity Progress Module
                            if downloadService.isDownloading {
                                VStack(spacing: 12) {
                                    // Custom Linear Progress bar track
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.06))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .pink.opacity(0.8)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            // Evaluates width gracefully against container bounding box boundaries
                                            .frame(width: max(0, (UIScreen.main.bounds.width - 48) * downloadService.progress), height: 6)
                                            .shadow(color: .purple.opacity(0.5), radius: 4, x: 0, y: 0)
                                    }
                                    
                                    HStack {
                                        Text("\(Int(downloadService.progress * 100))%")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.purple)
                                        
                                        Spacer()
                                        
                                        Text(downloadService.statusMessage.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(0.8)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(14)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Import Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .alert("Download Complete", isPresented: .init(
                get: { downloadService.downloadedSong != nil },
                set: { if !$0 { downloadService.downloadedSong = nil } }
            )) {
                Button("Add to Library") {
                    if let song = downloadService.downloadedSong {
                        viewModel.addSong(song)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                    downloadService.downloadedSong = nil
                }
            } message: {
                if let song = downloadService.downloadedSong {
                    Text("\"\(song.title)\" has been downloaded. Add it to your library?")
                }
            }
        }
    }
    
    private func startDownload() {
        Task {
            do {
                _ = try await downloadService.downloadAudio(from: youtubeURL)
                youtubeURL = ""
            } catch {
                print("Download error: \(error)")
            }
        }
    }
}
