import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Binding var isPresented: Bool

    @State private var selectedMinutes: Int = 15
    @State private var displayedRemaining: TimeInterval = 0
    @State private var refreshTimer: Timer?

    let options = [5, 10, 15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            ZStack {
                // Premium dark gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.02, blue: 0.16),
                        Color(red: 0.10, green: 0.04, blue: 0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {

                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.purple.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 8)

                    // Active Timer Countdown
                    if viewModel.sleepTimerActive {
                        activeTimerDisplay
                    }

                    // Duration Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Set Duration")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(options, id: \.self) { minutes in
                                TimerOptionButton(
                                    minutes: minutes,
                                    isSelected: selectedMinutes == minutes
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedMinutes = minutes
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: startTimer) {
                            HStack(spacing: 8) {
                                Image(systemName: "moon.fill")
                                Text(viewModel.sleepTimerActive ? "Update Timer" : "Start Timer")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.purple.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)
                        }

                        if viewModel.sleepTimerActive {
                            Button(action: cancelTimer) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark")
                                    Text("Cancel Timer")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.white.opacity(0.07))
                                .foregroundColor(.red.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Sleep Timer")
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
        .presentationDetents([.height(viewModel.sleepTimerActive ? 480 : 420)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .onAppear {
            displayedRemaining = viewModel.timeRemainingInSleepTimer ?? 0
            startRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
    }

    // MARK: - Active Timer Display
    @ViewBuilder
    private var activeTimerDisplay: some View {
        VStack(spacing: 6) {
            Text(formatRemaining(displayedRemaining))
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("remaining")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerProgress)

                Image(systemName: "moon.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers
    private var timerProgress: Double {
        guard let endTime = viewModel.sleepTimerEndTime else { return 0 }
        let total = endTime.timeIntervalSince(endTime.addingTimeInterval(-TimeInterval(selectedMinutes * 60)))
        guard total > 0 else { return 0 }
        return min(1, displayedRemaining / total)
    }

    private func formatRemaining(_ time: TimeInterval) -> String {
        guard time > 0 else { return "0:00" }
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    self.displayedRemaining = self.viewModel.timeRemainingInSleepTimer ?? 0
                }
            }
        }
    }

    private func startTimer() {
        viewModel.startSleepTimer(minutes: selectedMinutes)
        displayedRemaining = TimeInterval(selectedMinutes * 60)
        startRefreshTimer()
    }

    private func cancelTimer() {
        viewModel.cancelSleepTimer()
        displayedRemaining = 0
        isPresented = false
    }
}

// MARK: - Timer Option Button
struct TimerOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var label: String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color.white.opacity(0.07), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 1)
                )
                .shadow(color: isSelected ? Color.purple.opacity(0.35) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
