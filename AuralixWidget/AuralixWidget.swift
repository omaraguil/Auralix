import WidgetKit
import SwiftUI

private let appGroupID = "group.com.omaraguil.auralix"

// MARK: - Timeline Entry
struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let isPlaying: Bool
    let artworkData: Data?
    let progress: Double
    let currentTime: String
    let duration: String
    
    static let placeholder = NowPlayingEntry(
        date: .now,
        title: "Midnight Drive",
        artist: "The Weeknd",
        isPlaying: true,
        artworkData: nil,
        progress: 0.42,
        currentTime: "1:48",
        duration: "4:16"
    )
}

// MARK: - Provider
struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(currentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Date().addingTimeInterval(30)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func currentEntry() -> NowPlayingEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        return NowPlayingEntry(
            date: .now,
            title: defaults?.string(forKey: "widget_title") ?? "Not Playing",
            artist: defaults?.string(forKey: "widget_artist") ?? "—",
            isPlaying: defaults?.bool(forKey: "widget_isPlaying") ?? false,
            artworkData: defaults?.data(forKey: "widget_artwork"),
            progress: defaults?.double(forKey: "widget_progress") ?? 0,
            currentTime: defaults?.string(forKey: "widget_currentTime") ?? "0:00",
            duration: defaults?.string(forKey: "widget_duration") ?? "0:00"
        )
    }
}

// MARK: - Premium Glass Components

struct GlassBackground: View {
    let artworkData: Data?
    
    var body: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.04, blue: 0.18),
                    Color(red: 0.12, green: 0.08, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Blurred artwork overlay
            if let data = artworkData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 60)
                    .opacity(0.3)
                    .blendMode(.overlay)
            }
            
            // Glass noise texture
            Color.white.opacity(0.03)
                .blendMode(.overlay)
            
            // Subtle vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.4)],
                center: .center,
                startRadius: 100,
                endRadius: 200
            )
        }
    }
}

struct GlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

struct PremiumArtworkView: View {
    let data: Data?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let data = data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.20, blue: 0.55),
                                Color(red: 0.25, green: 0.15, blue: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.35, weight: .thin))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            }
        }
    }
}

struct AnimatedWaveform: View {
    @State private var heights: [CGFloat] = [8, 12, 6, 14, 8]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink.opacity(0.7)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: heights[i])
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.1),
                        value: heights[i]
                    )
                    .onAppear {
                        heights = [18, 24, 14, 20, 16]
                    }
            }
        }
    }
}

struct PremiumProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                
                // Glow effect
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple.opacity(0.5))
                    .frame(width: geometry.size.width * progress, height: 4)
                    .blur(radius: 2)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Premium Small Widget
struct PremiumSmallWidget: View {
    let entry: NowPlayingEntry
    
    var body: some View {
        ZStack {
            GlassBackground(artworkData: entry.artworkData)
            
            VStack(alignment: .leading, spacing: 10) {
                // Artwork
                PremiumArtworkView(data: entry.artworkData, size: 55)
                
                Spacer(minLength: 0)
                
                // Title
                Text(entry.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Artist
                Text(entry.artist)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                
                // Status
                if entry.isPlaying {
                    HStack(spacing: 4) {
                        AnimatedWaveform()
                            .frame(height: 12)
                        Text("PLAYING")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.purple)
                            .tracking(1)
                    }
                } else {
                    Text("PAUSED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Premium Medium Widget
struct PremiumMediumWidget: View {
    let entry: NowPlayingEntry
    
    var body: some View {
        ZStack {
            GlassBackground(artworkData: entry.artworkData)
            
            HStack(spacing: 16) {
                // Artwork
                PremiumArtworkView(data: entry.artworkData, size: 100)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Status badge
                    ZStack {
                        GlassCard()
                            .frame(width: 120, height: 27)
                        HStack(spacing: 6) {
                            if entry.isPlaying {
                                AnimatedWaveform()
                                    .frame(height: 10)
                            } else {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 8))
                            }
                            Text(entry.isPlaying ? "NOW PLAYING" : "PAUSED")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.2)
                        }
                        .foregroundColor(entry.isPlaying ? .purple : .white.opacity(0.5))
                    }
                    .frame(height: 24)
                    
                    Spacer(minLength: 4)
                    
                    // Title
                    Text(entry.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Artist
                    Text(entry.artist)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Progress section
                    VStack(spacing: 6) {
                        PremiumProgressBar(progress: entry.progress)
                        
                        HStack {
                            Text(entry.currentTime)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text(entry.duration)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Premium Large Widget
struct PremiumLargeWidget: View {
    let entry: NowPlayingEntry
    
    var body: some View {
        ZStack {
            GlassBackground(artworkData: entry.artworkData)
            
            VStack(spacing: 16) {
                // Top section with artwork and basic info
                HStack(spacing: 20) {
                    PremiumArtworkView(data: entry.artworkData, size: 110)
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Status badge
                        ZStack {
                            GlassCard()
                                .frame(width: 100, height: 26)
                            HStack(spacing: 6) {
                                if entry.isPlaying {
                                    AnimatedWaveform()
                                        .frame(height: 11)
                                } else {
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 9))
                                }
                                Text(entry.isPlaying ? "PLAYING" : "PAUSED")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.2)
                            }
                            .foregroundColor(entry.isPlaying ? .purple : .white.opacity(0.5))
                        }
                        .frame(height: 26)
                        
                        Text(entry.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(entry.artist)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer(minLength: 8)
                
                // Progress section with glass card
                VStack(spacing: 10) {
                    PremiumProgressBar(progress: entry.progress)
                    
                    HStack {
                        Text(entry.currentTime)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        Text(entry.duration)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(16)
                .background(GlassCard())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

// MARK: - Entry View
struct AuralixWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            PremiumSmallWidget(entry: entry)
        case .systemMedium:
            PremiumMediumWidget(entry: entry)
        case .systemLarge:
            PremiumLargeWidget(entry: entry)
        default:
            PremiumMediumWidget(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
@main
struct AuralixWidget: Widget {
    let kind = "AuralixWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
            AuralixWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Auralix")
        .description("Premium music player widget")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
