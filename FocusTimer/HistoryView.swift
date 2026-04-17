//
//  HistoryView.swift
//  JustZen
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var groupedSessions: [(String, [FocusSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dataManager.sessions.filter { $0.type == .work && $0.completed }) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return grouped
            .map { ($0.key, $0.value) }
            .sorted { $0.0 > $1.0 }
            .map { (date, sessions) in
                let formatter = DateFormatter()
                if calendar.isDateInToday(date) {
                    return ("Today", sessions)
                } else if calendar.isDateInYesterday(date) {
                    return ("Yesterday", sessions)
                } else {
                    formatter.dateFormat = "EEEE, MMM d"
                    return (formatter.string(from: date), sessions)
                }
            }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                if groupedSessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(groupedSessions, id: \.0) { day, sessions in
                                DaySection(day: day, sessions: sessions)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .toolbarBackground(Color(hex: "1C1C1E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "3A3A3C"))
            
            Text("No sessions yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Complete your first focus session\nto see your history here")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8E8E93"))
                .multilineTextAlignment(.center)
        }
    }
}

struct DaySection: View {
    let day: String
    let sessions: [FocusSession]
    
    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.duration } / 60
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(sessions.count) sessions • \(totalMinutes) min")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            VStack(spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    SessionRow(session: session)
                    
                    if index < sessions.count - 1 {
                        Divider()
                            .background(Color(hex: "3A3A3C"))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(hex: "2C2C2E"))
            .cornerRadius(12)
        }
    }
}

struct SessionRow: View {
    let session: FocusSession
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var durationMinutes: Int {
        session.duration / 60
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "circle.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "FF6B6B"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Session")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Text(timeFormatter.string(from: session.startTime))
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Spacer()
            
            Text("\(durationMinutes) min")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "4ECB71"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    HistoryView()
}
