//
//  MoodEnergyLogging.swift
//  FocusTimer
//
//  F53: Mood + Energy Logging before sessions
import Foundation
import Combine
import SwiftUI
//

import Foundation
import Combine

// MARK: - Mood & Energy Models

enum FocusMood: String, Codable, CaseIterable {
    case terrible = "terrible"
    case okay = "okay"  
    case good = "good"
    case great = "great"
    
    var emoji: String {
        switch self {
        case .terrible: return "😔"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        }
    }
    
    var displayName: String {
        switch self {
        case .terrible: return "Terrible"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }
    
    var energyBoost: Double {
        switch self {
        case .terrible: return 0.6
        case .okay: return 0.8
        case .good: return 1.0
        case .great: return 1.2
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case full = "full"
    
    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.75"
        case .full: return "battery.100"
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .full: return "Full"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .low: return 0.7
        case .medium: return 0.9
        case .high: return 1.0
        case .full: return 1.1
        }
    }
}

// MARK: - Session Mood Entry

struct MoodEnergyEntry: Codable {
    let id: UUID
    let date: Date
    let mood: FocusMood
    let energy: EnergyLevel
    let sessionId: UUID?
    let completed: Bool
    
    init(mood: FocusMood, energy: EnergyLevel, sessionId: UUID? = nil, completed: Bool = false) {
        self.id = UUID()
        self.date = Date()
        self.mood = mood
        self.energy = energy
        self.sessionId = sessionId
        self.completed = completed
    }
}

// MARK: - Mood Energy Manager

class MoodEnergyManager: ObservableObject {
    static let shared = MoodEnergyManager()
    
    @Published var currentMood: FocusMood = .good
    @Published var currentEnergy: EnergyLevel = .medium
    @Published var todayEntries: [MoodEnergyEntry] = []
    @Published var pendingEntry: MoodEnergyEntry?
    @Published var showMoodPicker: Bool = false
    
    private let dataManager = FocusDataManager.shared
    private let intelligence = FocusIntelligence.shared
    
    private init() {
        load()
    }
    
    // MARK: - Pre-Session Logging
    
    func prepareForSession() {
        showMoodPicker = true
    }
    
    func logMoodEnergy(mood: FocusMood, energy: EnergyLevel) -> MoodEnergyEntry {
        let entry = MoodEnergyEntry(mood: mood, energy: energy)
        todayEntries.append(entry)
        pendingEntry = entry
        showMoodPicker = false
        save()
        
        // Update current selections for next time
        currentMood = mood
        currentEnergy = energy
        
        return entry
    }
    
    func completeSession(entryId: UUID) {
        if let index = todayEntries.firstIndex(where: { $0.id == entryId }) {
            let old = todayEntries[index]
            todayEntries[index] = MoodEnergyEntry(
                mood: old.mood,
                energy: old.energy,
                sessionId: old.sessionId,
                completed: true
            )
            save()
        }
    }
    
    func cancelPendingEntry() {
        pendingEntry = nil
        showMoodPicker = false
    }
    
    // MARK: - Analytics
    
    func getMoodCorrelation() -> [String: Double] {
        // Calculate completion rate by mood
        var correlation: [FocusMood: (completed: Int, total: Int)] = [:]
        
        for entry in todayEntries {
            var stats = correlation[entry.mood] ?? (completed: 0, total: 0)
            stats.total += 1
            if entry.completed {
                stats.completed += 1
            }
            correlation[entry.mood] = stats
        }
        
        var result: [String: Double] = [:]
        for (mood, stats) in correlation {
            if stats.total > 0 {
                result[mood.displayName] = Double(stats.completed) / Double(stats.total)
            }
        }
        
        return result
    }
    
    func getEnergyCorrelation() -> [String: Double] {
        var correlation: [EnergyLevel: (completed: Int, total: Int)] = [:]
        
        for entry in todayEntries {
            var stats = correlation[entry.energy] ?? (completed: 0, total: 0)
            stats.total += 1
            if entry.completed {
                stats.completed += 1
            }
            correlation[entry.energy] = stats
        }
        
        var result: [String: Double] = [:]
        for (energy, stats) in correlation {
            if stats.total > 0 {
                result[energy.displayName] = Double(stats.completed) / Double(stats.total)
            }
        }
        
        return result
    }
    
    func getMoodInsight() -> String? {
        let moodCorr = getMoodCorrelation()
        guard !moodCorr.isEmpty else { return nil }
        
        // Find best mood
        if let best = moodCorr.max(by: { $0.value < $1.value }) {
            if best.value > 0.7 {
                return "You complete \(Int(best.value * 100))% of sessions when feeling \(best.key.lowercased())!"
            }
        }
        
        return nil
    }
    
    func getAverageCompletionRate() -> Double {
        let completed = todayEntries.filter { $0.completed }.count
        guard !todayEntries.isEmpty else { return 0 }
        return Double(completed) / Double(todayEntries.count)
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(todayEntries) {
            UserDefaults.standard.set(encoded, forKey: "mood_energy_entries")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "mood_energy_entries"),
           let decoded = try? JSONDecoder().decode([MoodEnergyEntry].self, from: data) {
            // Only keep today's entries
            let calendar = Calendar.current
            todayEntries = decoded.filter { calendar.isDateInToday($0.date) }
        }
    }
    
    func resetIfNewDay() {
        let calendar = Calendar.current
        let hasTodayEntry = todayEntries.contains { calendar.isDateInToday($0.date) }
        
        if !hasTodayEntry && !todayEntries.isEmpty {
            // Archive yesterday's entries for analysis before clearing
            intelligence.analyzeMoodCorrelation(entries: todayEntries)
        }
        
        todayEntries = []
        pendingEntry = nil
        save()
    }
}

// MARK: - Focus Intelligence Mood Analysis Extension

extension FocusIntelligence {
    func analyzeMoodCorrelation(entries: [MoodEnergyEntry]) {
        guard entries.count >= 3 else { return }
        
        var moodStats: [FocusMood: Int] = [:]
        var energyStats: [EnergyLevel: Int] = [:]
        
        for entry in entries {
            if entry.completed {
                moodStats[entry.mood, default: 0] += 1
                energyStats[entry.energy, default: 0] += 1
            }
        }
        
        // Find best performing mood
        if let bestMood = moodStats.max(by: { $0.value < $1.value }) {
            let insight = "You seem to focus best when feeling \(bestMood.key.displayName.lowercased())!"
            addInsight(text: insight, category: .pattern, importance: .medium)
        }
        
        // Find best energy level
        if let bestEnergy = energyStats.max(by: { $0.value < $1.value }) {
            let insight = "Your completion rate is highest at \(bestEnergy.key.displayName.lowercased()) energy."
            addInsight(text: insight, category: .pattern, importance: .low)
        }
    }
}
