//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var isWorkPhase: Bool = true
    @State private var currentSessionIndex: Int = 0
    @State private var timer: Timer? = nil
    @State private var sessionStartTime: Date = Date()
    @State private var showSettings: Bool = false
    @State private var showStatistics: Bool = false
    @State private var showHistory: Bool = false
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { showStatistics = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    
                    Spacer()
                    
                    // Daily goal indicator
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 14))
                        Text("\(dataManager.statistics.todaySessions)/\(dataManager.settings.dailyGoal)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(dataManager.statistics.todaySessions >= dataManager.settings.dailyGoal ? Color(hex: "4ECB71") : Color(hex: "8E8E93"))
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Phase label
                Text(phaseLabel)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(phaseColor)
                    .padding(.bottom, 8)
                
                // Session indicator
                HStack(spacing: 8) {
                    ForEach(0..<dataManager.settings.sessionsUntilLongBreak, id: \.self) { index in
                        Circle()
                            .fill(index < currentSessionIndex ? Color(hex: "4ECB71") : (index == currentSessionIndex && isWorkPhase ? phaseColor : Color(hex: "3A3A3C")))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom, 32)
                
                // Timer circle
                ZStack {
                    Circle()
                        .stroke(Color(hex: "3A3A3C"), lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            phaseColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    VStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Text("\(dataManager.statistics.todayMinutes) min focused today")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
                .frame(width: 280, height: 280)
                .padding(.bottom, 40)
                
                // Control buttons
                HStack(spacing: 32) {
                    // Reset button
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "3A3A3C"))
                            .clipShape(Circle())
                    }
                    
                    // Play/Pause button
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .frame(width: 88, height: 88)
                            .background(phaseColor)
                            .clipShape(Circle())
                    }
                    
                    // Skip button
                    Button(action: skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "3A3A3C"))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                // Streak indicator
                if dataManager.statistics.currentStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(dataManager.statistics.currentStreak) day streak!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "3A3A3C"))
                    .cornerRadius(20)
                    .padding(.bottom, 32)
                } else {
                    Spacer().frame(height: 52)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if isRunning {
                // App going to background - keep timer running
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var phaseLabel: String {
        if isWorkPhase {
            return "Focus Time"
        } else if currentSessionIndex >= dataManager.settings.sessionsUntilLongBreak - 1 {
            return "Long Break"
        } else {
            return "Short Break"
        }
    }
    
    private var phaseColor: Color {
        isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71")
    }
    
    private var progress: Double {
        let total = Double(currentPhaseDuration)
        return Double(currentPhaseDuration - timeRemaining) / total
    }
    
    private var currentPhaseDuration: Int {
        if isWorkPhase {
            return dataManager.settings.workDuration
        } else if currentSessionIndex >= dataManager.settings.sessionsUntilLongBreak - 1 {
            return dataManager.settings.longBreakDuration
        } else {
            return dataManager.settings.shortBreakDuration
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        sessionStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completePhase()
            }
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        dataManager.cancelAllNotifications()
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = currentPhaseDuration
    }
    
    private func skipToNext() {
        stopTimer()
        moveToNextPhase()
    }
    
    private func completePhase() {
        stopTimer()
        dataManager.playSound()
        
        if isWorkPhase {
            let session = FocusSession(
                startTime: sessionStartTime,
                endTime: Date(),
                duration: dataManager.settings.workDuration,
                type: .work,
                completed: true
            )
            dataManager.addSession(session)
            
            currentSessionIndex += 1
            if currentSessionIndex >= dataManager.settings.sessionsUntilLongBreak {
                currentSessionIndex = 0
                isWorkPhase = false
                timeRemaining = dataManager.settings.longBreakDuration
                dataManager.scheduleNotification(title: "Long Break!", body: "Great work! Time for a 15 minute break.", timeInterval: 1)
            } else {
                isWorkPhase = false
                timeRemaining = dataManager.settings.shortBreakDuration
                dataManager.scheduleNotification(title: "Short Break!", body: "Good job! Take a 5 minute break.", timeInterval: 1)
            }
        } else {
            isWorkPhase = true
            timeRemaining = dataManager.settings.workDuration
            dataManager.scheduleNotification(title: "Focus Time!", body: "Ready to focus again?", timeInterval: 1)
        }
    }
    
    private func moveToNextPhase() {
        if isWorkPhase {
            isWorkPhase = false
            timeRemaining = dataManager.settings.shortBreakDuration
        } else {
            isWorkPhase = true
            timeRemaining = dataManager.settings.workDuration
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
