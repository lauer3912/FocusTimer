//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI

struct ContentView: View {
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var isWorkPhase: Bool = true
    @State private var sessionsCompleted: Int = 0
    @State private var timer: Timer? = nil
    
    private let workDuration: Int = 25 * 60
    private let breakDuration: Int = 5 * 60
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text(isWorkPhase ? "Focus Time" : "Break Time")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .stroke(Color(hex: "3A3A3C"), lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71"),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    VStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Session \(sessionsCompleted + 1)")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
                .frame(width: 280, height: 280)
                
                HStack(spacing: 24) {
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "3A3A3C"))
                            .clipShape(Circle())
                    }
                    
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(isWorkPhase ? Color(hex: "FF6B6B") : Color(hex: "4ECB71"))
                            .clipShape(Circle())
                    }
                    
                    Button(action: skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "3A3A3C"))
                            .clipShape(Circle())
                    }
                }
                
                if sessionsCompleted > 0 {
                    Text("\(sessionsCompleted) session\(sessionsCompleted == 1 ? "" : "s") completed today!")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    private var progress: Double {
        let total = isWorkPhase ? Double(workDuration) : Double(breakDuration)
        return Double(workDuration - timeRemaining) / total
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
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
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = isWorkPhase ? workDuration : breakDuration
    }
    
    private func skipToNext() {
        stopTimer()
        completePhase()
    }
    
    private func completePhase() {
        stopTimer()
        if isWorkPhase {
            sessionsCompleted += 1
            isWorkPhase = false
            timeRemaining = breakDuration
        } else {
            isWorkPhase = true
            timeRemaining = workDuration
        }
    }
}

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
