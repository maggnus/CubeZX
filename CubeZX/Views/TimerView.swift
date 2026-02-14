//
//  TimerView.swift
//  CubeSync
//
//  Professional speedcubing timer with csTimer-inspired features
//

import SwiftUI

struct TimerView: View {
    @State private var timerState: TimerState = .idle
    @State private var elapsedTime: TimeInterval = 0
    @State private var inspectionTime: Int = 15
    @State private var scramble: String = "R U R' U' R' F R2 U' R' U' R U R' F'"
    @State private var solves: [Solve] = []
    
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    private let inspectionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color.deepVoid.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Session stats header
                sessionStatsHeader
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        // Scramble display
                        scrambleCard
                        
                        // Timer display
                        timerDisplay
                        
                        Spacer(minLength: 20)
                        
                        // Recent solves list
                        solvesList
                    }
                    .padding()
                }
            }
        }
        .onReceive(timer) { _ in
            if timerState == .solving {
                elapsedTime += 0.01
            }
        }
        .onReceive(inspectionTimer) { _ in
            if timerState == .inspecting && inspectionTime > 0 {
                inspectionTime -= 1
            }
        }
    }
    
    // MARK: - Session Stats Header
    
    private var sessionStatsHeader: some View {
        GlassCard(cornerRadius: 0, showBorder: false) {
            HStack(spacing: 20) {
                StatItem(value: "\(solves.count)", label: "Solves")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                StatItem(value: formatTime(sessionAverage), label: "Session Avg")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                StatItem(value: formatTime(bestTime), label: "Best")
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Scramble Card
    
    private var scrambleCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("SCRAMBLE")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textSecondary)
                        .tracking(1.5)
                    
                    Spacer()
                    
                    Button(action: generateNewScramble) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .glassButton()
                }
                
                Text(scramble)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(3)
                
                HStack(spacing: 12) {
                    Button(action: copyScramble) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .glassButton()
                    
                    Button(action: show3DScramble) {
                        Label("3D", systemImage: "cube.transparent")
                            .font(.caption)
                    }
                    .glassButton()
                }
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 16) {
            // Main timer
            ZStack {
                // Background card for touch target
                Group {
                    if timerState == .solving {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.solarOrange.opacity(0.1))
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            timerState == .solving ? Color.solarOrange.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: timerState == .solving ? 2 : 1
                        )
                )
                
                VStack(spacing: 8) {
                    if timerState == .inspecting {
                        // Inspection countdown
                        Text("\(inspectionTime)")
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .foregroundColor(inspectionColor)
                    } else {
                        // Main timer display
                        Text(formattedElapsedTime)
                            .font(.system(size: 72, weight: .bold, design: .monospaced))
                            .fontWidth(.expanded)
                            .foregroundColor(timerState == .solving ? .solarOrange : .white)
                            .minimumScaleFactor(0.5)
                    }
                    
                    Text(timerHint)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 40)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                handleTimerTap()
            }
            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                if pressing && timerState == .idle {
                    timerState = .ready
                } else if !pressing && timerState == .ready {
                    startInspection()
                }
            }, perform: {})
        }
    }
    
    // MARK: - Solves List
    
    private var solvesList: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("SESSION")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textSecondary)
                        .tracking(1.5)
                    
                    Spacer()
                    
                    if !solves.isEmpty {
                        Button(action: clearSession) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.alertRed)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if solves.isEmpty {
                    Text("No solves yet")
                        .font(.subheadline)
                        .foregroundColor(.textTertiary)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 8) {
                        ForEach(solves.prefix(5).indices, id: \.self) { index in
                            SolveRow(
                                solve: solves[solves.count - 1 - index],
                                rank: solves.count - index
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        } else {
            return String(format: "%02d.%02d", seconds, centiseconds)
        }
    }
    
    private var timerHint: String {
        switch timerState {
        case .idle:
            return "Hold to start inspection"
        case .ready:
            return "Release to start"
        case .inspecting:
            return "Tap to start solving"
        case .solving:
            return "Tap to stop"
        case .finished:
            return "Tap for next solve"
        }
    }
    
    private var inspectionColor: Color {
        if inspectionTime > 8 {
            return .white
        } else if inspectionTime > 3 {
            return .solarOrange
        } else {
            return .alertRed
        }
    }
    
    private var sessionAverage: TimeInterval {
        guard solves.count >= 3 else { return 0 }
        let times = solves.map { $0.time }
        let sorted = times.sorted()
        let trimmed = sorted.dropFirst().dropLast()
        return trimmed.reduce(0, +) / Double(trimmed.count)
    }
    
    private var bestTime: TimeInterval {
        solves.map { $0.time }.min() ?? 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time == 0 { return "--" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        } else {
            return String(format: "%d.%02d", seconds, centiseconds)
        }
    }
    
    // MARK: - Actions
    
    private func handleTimerTap() {
        switch timerState {
        case .idle, .ready:
            break
        case .inspecting:
            timerState = .solving
            elapsedTime = 0
        case .solving:
            finishSolve()
        case .finished:
            resetTimer()
        }
    }
    
    private func startInspection() {
        timerState = .inspecting
        inspectionTime = 15
    }
    
    private func finishSolve() {
        timerState = .finished
        let solve = Solve(
            id: UUID(),
            time: elapsedTime,
            scramble: scramble,
            date: Date()
        )
        solves.append(solve)
    }
    
    private func resetTimer() {
        timerState = .idle
        elapsedTime = 0
        generateNewScramble()
    }
    
    private func generateNewScramble() {
        // Generate a random WCA scramble
        let moves = ["R", "L", "U", "D", "F", "B"]
        let modifiers = ["", "'", "2"]
        var scrambleMoves: [String] = []
        
        for _ in 0..<20 {
            let move = moves.randomElement()!
            let modifier = modifiers.randomElement()!
            scrambleMoves.append(move + modifier)
        }
        
        scramble = scrambleMoves.joined(separator: " ")
    }
    
    private func copyScramble() {
        // Copy to clipboard
    }
    
    private func show3DScramble() {
        // Show 3D scramble preview
    }
    
    private func clearSession() {
        solves.removeAll()
    }
}

// MARK: - Supporting Types

enum TimerState {
    case idle
    case ready
    case inspecting
    case solving
    case finished
}

struct Solve: Identifiable {
    let id: UUID
    let time: TimeInterval
    let scramble: String
    let date: Date
    var isDNF: Bool = false
    var isPlusTwo: Bool = false
}

// MARK: - Helper Views

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SolveRow: View {
    let solve: Solve
    let rank: Int
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .frame(width: 30, alignment: .leading)
            
            Text(formattedTime(solve.time))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            if solve.isPlusTwo {
                Text("+2")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.solarOrange)
            }
            
            if solve.isDNF {
                Text("DNF")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.alertRed)
            }
            
            Text(formattedDate(solve.date))
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        } else {
            return String(format: "%d.%02d", seconds, centiseconds)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Timer View") {
    TimerView()
}
