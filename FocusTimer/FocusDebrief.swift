//
//  FocusDebrief.swift
//  FocusTimer
//
//  F97: Focus Debrief - End-of-day reflection
import Foundation
import Combine
import SwiftUI
//  F41: Monthly Focus Calendar Export
//

import Foundation
import Combine
import PDFKit

// MARK: - Debrief Entry

struct DebriefEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var wins: String
    var challenges: String
    var tomorrowPlan: String
    var moodRating: Int // 1-5
    var energyRating: Int // 1-5
    
    init(wins: String, challenges: String, tomorrowPlan: String, moodRating: Int, energyRating: Int) {
        self.id = UUID()
        self.date = Date()
        self.wins = wins
        self.challenges = challenges
        self.tomorrowPlan = tomorrowPlan
        self.moodRating = moodRating
        self.energyRating = energyRating
    }
}

// MARK: - Debrief Manager

class DebriefManager: ObservableObject {
    static let shared = DebriefManager()
    
    @Published var todayDebrief: DebriefEntry?
    @Published var showDebriefPrompt: Bool = false
    @Published var debriefHistory: [DebriefEntry] = []
    @Published var pendingDebrief: Bool = false
    
    private let dataManager = FocusDataManager.shared
    private let intelligence = FocusIntelligence.shared
    
    private init() {
        load()
        checkIfDebriefNeeded()
    }
    
    func checkIfDebriefNeeded() {
        let calendar = Calendar.current
        
        // Check if we had sessions today
        let hadSessions = !dataManager.sessions.isEmpty && 
            dataManager.sessions.contains { calendar.isDateInToday($0.startTime) }
        
        // Check if we already did debrief today
        let alreadyDebriefed = debriefHistory.contains { calendar.isDateInToday($0.date) }
        
        pendingDebrief = hadSessions && !alreadyDebriefed
    }
    
    func saveDebrief(wins: String, challenges: String, tomorrowPlan: String, moodRating: Int, energyRating: Int) {
        let entry = DebriefEntry(
            wins: wins,
            challenges: challenges,
            tomorrowPlan: tomorrowPlan,
            moodRating: moodRating,
            energyRating: energyRating
        )
        todayDebrief = entry
        debriefHistory.append(entry)
        pendingDebrief = false
        save()
        
        // Generate insight from debrief
        if !wins.isEmpty {
            intelligence.addInsight(
                text: "Today you celebrated: \(wins.prefix(50))...",
                category: .reflection,
                importance: .low
            )
        }
    }
    
    func getThisWeekDebriefs() -> [DebriefEntry] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], for: Date()))!
        
        return debriefHistory.filter { $0.date >= startOfWeek }
    }
    
    func getDebriefInsight() -> String? {
        let thisWeek = getThisWeekDebriefs()
        guard thisWeek.count >= 3 else { return nil }
        
        let avgMood = thisWeek.reduce(0) { $0 + $1.moodRating } / thisWeek.count
        let avgEnergy = thisWeek.reduce(0) { $0 + $1.energyRating } / thisWeek.count
        
        if avgMood >= 4 && avgEnergy >= 3 {
            return "You've had a great week! High mood and energy are driving your focus."
        } else if avgMood < 3 {
            return "Your mood has been lower this week. Consider adding more breaks or shorter sessions."
        } else if avgEnergy < 3 {
            return "Your energy levels have been low. Try focusing during your peak hours."
        }
        
        return nil
    }
    
    // MARK: - Export
    
    func exportToCSV() -> String {
        var csv = "Date,Wins,Challenges,Tomorrow Plan,Mood,Energy\n"
        
        let sortedHistory = debriefHistory.sorted { $0.date > $1.date }
        
        for entry in sortedHistory {
            let date = ISO8601DateFormatter().string(from: entry.date)
            let wins = entry.wins.replacingOccurrences(of: ",", with: ";")
            let challenges = entry.challenges.replacingOccurrences(of: ",", with: ";")
            let plan = entry.tomorrowPlan.replacingOccurrences(of: ",", with: ";")
            
            csv += "\(date),\"\(wins)\",\"\(challenges)\",\"\(plan)\",\(entry.moodRating),\(entry.energyRating)\n"
        }
        
        return csv
    }
    
    func exportToPDF(title: String = "FocusTimer Debrief") -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let pdfMetaData = [
            kCGPDFContextCreator: "FocusTimer",
            kCGPDFContextTitle: title
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            // Title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleString = NSAttributedString(string: title, attributes: titleAttrs)
            titleString.draw(at: CGPoint(x: margin, y: yPosition))
            yPosition += 40
            
            // Date range
            let dateFont = UIFont.systemFont(ofSize: 12)
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.gray
            ]
            
            let dateRange = "Generated on \(Date().formatted(date: .long, time: .shortened))"
            let dateString = NSAttributedString(string: dateRange, attributes: dateAttrs)
            dateString.draw(at: CGPoint(x: margin, y: yPosition))
            yPosition += 30
            
            // Summary stats
            let statsFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let statsAttrs: [NSAttributedString.Key: Any] = [
                .font: statsFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let stats = "Total Sessions: \(dataManager.statistics.totalSessions) | Total Minutes: \(dataManager.statistics.totalMinutes) | Current Streak: \(dataManager.statistics.currentStreak) days"
            let statsString = NSAttributedString(string: stats, attributes: statsAttrs)
            statsString.draw(at: CGPoint(x: margin, y: yPosition))
            yPosition += 40
            
            // Debrief entries
            let entryFont = UIFont.systemFont(ofSize: 12)
            let entryAttrs: [NSAttributedString.Key: Any] = [
                .font: entryFont,
                .foregroundColor: UIColor.black
            ]
            
            let boldFont = UIFont.systemFont(ofSize: 12, weight: .bold)
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: UIColor.black
            ]
            
            for entry in debriefHistory.sorted(by: { $0.date > $1.date }).prefix(30) {
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = margin
                }
                
                // Date header
                let dateHeader = NSAttributedString(string: entry.date.formatted(date: .abbreviated, time: .omitted), attributes: boldAttrs)
                dateHeader.draw(at: CGPoint(x: margin, y: yPosition))
                yPosition += 20
                
                // Mood/Energy
                let moodEnergy = NSAttributedString(string: "Mood: \(entry.moodRating)/5 | Energy: \(entry.energyRating)/5", attributes: entryAttrs)
                moodEnergy.draw(at: CGPoint(x: margin, y: yPosition))
                yPosition += 18
                
                // Wins
                if !entry.wins.isEmpty {
                    let wins = NSAttributedString(string: "Wins: \(entry.wins)", attributes: entryAttrs)
                    wins.draw(at: CGPoint(x: margin, y: yPosition))
                    yPosition += 18
                }
                
                // Challenges
                if !entry.challenges.isEmpty {
                    let challenges = NSAttributedString(string: "Challenges: \(entry.challenges)", attributes: entryAttrs)
                    challenges.draw(at: CGPoint(x: margin, y: yPosition))
                    yPosition += 18
                }
                
                // Tomorrow
                if !entry.tomorrowPlan.isEmpty {
                    let tomorrow = NSAttributedString(string: "Tomorrow: \(entry.tomorrowPlan)", attributes: entryAttrs)
                    tomorrow.draw(at: CGPoint(x: margin, y: yPosition))
                    yPosition += 18
                }
                
                yPosition += 20
            }
        }
        
        return data
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(debriefHistory) {
            UserDefaults.standard.set(encoded, forKey: "debrief_history")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "debrief_history"),
           let decoded = try? JSONDecoder().decode([DebriefEntry].self, from: data) {
            debriefHistory = decoded
        }
    }
}

// MARK: - Debrief View

struct FocusDebriefView: View {
    @StateObject private var debrief = DebriefManager.shared
    @StateObject private var dataManager = FocusDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var wins: String = ""
    @State private var challenges: String = ""
    @State private var tomorrowPlan: String = ""
    @State private var moodRating: Int = 3
    @State private var energyRating: Int = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary card
                        summaryCard
                        
                        // Reflection questions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reflection Questions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Wins
                            DebriefQuestion(
                                icon: "🏆",
                                title: "What went well today?",
                                placeholder: "I completed 4 focus sessions...",
                                text: $wins
                            )
                            
                            // Challenges
                            DebriefQuestion(
                                icon: "📚",
                                title: "What challenged you?",
                                placeholder: "I struggled with...",
                                text: $challenges
                            )
                            
                            // Tomorrow
                            DebriefQuestion(
                                icon: "🎯",
                                title: "What's the focus for tomorrow?",
                                placeholder: "I want to accomplish...",
                                text: $tomorrowPlan
                            )
                        }
                        
                        // Mood & Energy ratings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How are you feeling?")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            RatingRow(title: "Overall Mood", icon: "😊", rating: $moodRating)
                            RatingRow(title: "Energy Level", icon: "⚡", rating: $energyRating)
                        }
                        
                        // Save button
                        Button(action: saveDebrief) {
                            Text("Save Debrief")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSave ? Color(hex: "FF6B6B") : Color(hex: "3A3A3C"))
                                .cornerRadius(12)
                        }
                        .disabled(!canSave)
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Debrief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") { dismiss() }
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("📊")
                .font(.system(size: 36))
            
            Text("Today's Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                DebriefStat(value: "\(dataManager.statistics.todaySessions)", label: "Sessions")
                DebriefStat(value: "\(dataManager.statistics.todayMinutes)", label: "Minutes")
                DebriefStat(value: "\(dataManager.statistics.currentStreak)", label: "Streak")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    private var canSave: Bool {
        !wins.isEmpty || !challenges.isEmpty || !tomorrowPlan.isEmpty
    }
    
    private func saveDebrief() {
        debrief.saveDebrief(
            wins: wins,
            challenges: challenges,
            tomorrowPlan: tomorrowPlan,
            moodRating: moodRating,
            energyRating: energyRating
        )
        dismiss()
    }
}

struct DebriefStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct DebriefQuestion: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            TextEditor(text: $text)
                .frame(height: 80)
                .padding(8)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(8)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
        }
    }
}

struct RatingRow: View {
    let title: String
    let icon: String
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            Text(icon)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: { rating = index }) {
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .foregroundColor(index <= rating ? Color(hex: "FFD60A") : Color(hex: "3A3A3C"))
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(8)
    }
}

// MARK: - Focus Consistency Score

class FocusConsistencyScore {
    static func calculate(sessions: [FocusSession]) -> Double {
        let calendar = Calendar.current
        
        // Group sessions by day
        var sessionDays: Set<Date> = []
        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            sessionDays.insert(day)
        }
        
        guard !sessionDays.isEmpty else { return 0 }
        
        // Calculate consistency over last 30 days
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        
        var activeDays = 0
        var expectedDays = 30
        
        for dayOffset in 0..<30 {
            let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            if sessionDays.contains(checkDate) {
                activeDays += 1
            }
        }
        
        // Perfect consistency = 7 days per week
        // Calculate based on how regular the pattern is
        let baseScore = Double(activeDays) / 30.0
        
        // Bonus for regular daily practice
        let dayOfWeekCounts = [Int](repeating: 0, count: 7)
        for day in sessionDays {
            let weekday = calendar.component(.weekday, from: day)
            dayOfWeekCounts[weekday - 1] += 1
        }
        
        let variance = calculateVariance(dayOfWeekCounts)
        let regularityBonus = max(0, 1.0 - (variance / 10.0)) * 0.2
        
        return min(1.0, baseScore + regularityBonus)
    }
    
    private static func calculateVariance(_ values: [Int]) -> Double {
        guard !values.allSatisfy({ $0 == 0 }) else { return 0 }
        
        let mean = Double(values.reduce(0, +)) / Double(max(1, values.filter { $0 > 0 }.count))
        let squaredDiffs = values.map { pow(Double($0) - mean, 2) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count))
    }
}
