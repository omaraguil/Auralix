import SwiftUI
import AVFoundation
import Combine

struct EqualizerView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    private let freqLabels = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    private let barH: CGFloat = 160

    var body: some View {
        NavigationStack {
            ZStack {
                deepBackground
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        toggleSection
                        presetsSection
                        spectrumSection
                        resetSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Equalizer")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.60, green: 0.25, blue: 0.90))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    // MARK: - Background

    private var deepBackground: some View {
        ZStack {
            Color(red: 0.06, green: 0.03, blue: 0.16).ignoresSafeArea()
            RadialGradient(colors: [Color(red: 0.45, green: 0.15, blue: 0.75).opacity(0.35), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 400).ignoresSafeArea()
            RadialGradient(colors: [Color(red: 0.85, green: 0.25, blue: 0.55).opacity(0.12), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 350).ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.60, green: 0.25, blue: 0.90).opacity(0.18))
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(LinearGradient(colors: [.white.opacity(0.25), .clear],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
                    .frame(width: 72, height: 72)
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 0.80, green: 0.50, blue: 1.0),
                                 Color(red: 0.95, green: 0.40, blue: 0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Text("Studio EQ")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("10-Band Parametric Equalizer")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
        }
        .padding(.top, 16)
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(viewModel.eqEnabled
                          ? Color(red: 0.60, green: 0.25, blue: 0.90).opacity(0.2)
                          : Color.white.opacity(0.06))
                    .frame(width: 36, height: 36)
                Image(systemName: viewModel.eqEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(viewModel.eqEnabled
                                     ? Color(red: 0.60, green: 0.25, blue: 0.90)
                                     : .white.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Equalizer")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(viewModel.eqEnabled ? "Active" : "Bypassed")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(viewModel.eqEnabled
                                     ? Color(red: 0.60, green: 0.25, blue: 0.90)
                                     : .white.opacity(0.35))
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.eqEnabled },
                set: { viewModel.setEQEnabled($0) }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.60, green: 0.25, blue: 0.90)))
            .labelsHidden()
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(glassCard)
        .padding(.horizontal, 16)
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Presets")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EQPreset.allCases) { preset in
                        let active = viewModel.eqPreset == preset
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.applyEQPreset(preset)
                            }
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 14, weight: .medium))
                                Text(preset.rawValue)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(active ? .white : .white.opacity(0.5))
                            .frame(width: 66, height: 52)
                            .background(
                                Group {
                                    if active {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LinearGradient(
                                                colors: [Color(red: 0.60, green: 0.25, blue: 0.90),
                                                         Color(red: 0.85, green: 0.25, blue: 0.55)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .shadow(color: Color(red: 0.60, green: 0.25, blue: 0.90).opacity(0.5),
                                                    radius: 8, x: 0, y: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.07))
                                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }
        }
    }

    // MARK: - Spectrum

    private var spectrumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionLabel("Bands")
                Spacer()
                VStack(spacing: 0) {
                    Text("+12").font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text("0").font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text("-12").font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.3))
                }
                .frame(height: barH).padding(.trailing, 4)
            }
            .padding(.horizontal, 16)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<freqLabels.count, id: \.self) { i in
                    BandColumn(
                        frequency: freqLabels[i],
                        gain: Binding(
                            get: { viewModel.eqGains[i] },
                            set: { viewModel.setEQGain($0, at: i)
                                   viewModel.eqPreset = .flat }
                        ),
                        barHeight: barH,
                        accentColor: bandColor(for: i)
                    )
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 18)
            .background(glassCard.padding(.horizontal, 16))
            .padding(.horizontal, 16)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<freqLabels.count, id: \.self) { i in
                    Text(freqLabels[i])
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16).padding(.top, -10)
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                viewModel.resetEQ()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                Text("Reset to Flat")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 28).padding(.vertical, 13)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().stroke(
                        LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.8)
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain).padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))
            .tracking(1.5).padding(.horizontal, 16)
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.9))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private func bandColor(for index: Int) -> Color {
        let t = Double(index) / Double(freqLabels.count - 1)
        return Color(red: 0.45 + 0.50 * t, green: 0.10 + 0.15 * t, blue: 0.90 - 0.35 * t)
    }
}

// MARK: - Band Column

private struct BandColumn: View {
    let frequency: String
    @Binding var gain: Float
    let barHeight: CGFloat
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            // dB label
            Text(gain == 0 ? "0" : (gain > 0 ? "+\(Int(gain))" : "\(Int(gain))"))
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundStyle(gain == 0 ? .white.opacity(0.35) : accentColor)
                .frame(height: 14)

            GeometryReader { geo in
                let trackH  = geo.size.height
                let norm    = CGFloat((gain + 12) / 24)          // 0…1
                let thumbY  = trackH * (1 - norm)                // top=+12 bottom=-12
                let midY    = trackH * 0.5
                let fillTop = min(thumbY, midY)
                let fillH   = abs(midY - thumbY)

                ZStack(alignment: .top) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 4, height: trackH)
                        .frame(maxWidth: .infinity)

                    // Zero tick
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 10, height: 1)
                        .offset(y: midY)
                        .frame(maxWidth: .infinity)

                    // Fill
                    Capsule()
                        .fill(LinearGradient(
                            colors: [accentColor.opacity(0.9), accentColor.opacity(0.4)],
                            startPoint: gain >= 0 ? .bottom : .top,
                            endPoint:   gain >= 0 ? .top    : .bottom))
                        .frame(width: 4, height: max(fillH, 1))
                        .offset(y: fillTop)
                        .frame(maxWidth: .infinity)

                    // Glow
                    Capsule()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 4, height: max(fillH, 1))
                        .blur(radius: 4)
                        .offset(y: fillTop)
                        .frame(maxWidth: .infinity)

                    // Thumb
                    ZStack {
                        Circle().fill(accentColor).frame(width: 18, height: 18)
                            .shadow(color: accentColor.opacity(0.6), radius: 6)
                        Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.8).frame(width: 18, height: 18)
                        Circle().fill(.white).frame(width: 5, height: 5)
                    }
                    .offset(y: thumbY - 9)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: barHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    let raw     = 1 - Float(value.location.y / barHeight)
                    let clamped = max(0, min(1, raw))
                    let dB      = (clamped * 24) - 12
                    // Snap to nearest integer dB, with a ±0.4 dB dead-zone at 0
                    gain = abs(dB) < 0.4 ? 0 : (dB * 12).rounded() / 12
                }
            )
        }
        .frame(maxWidth: .infinity)
    }
}
