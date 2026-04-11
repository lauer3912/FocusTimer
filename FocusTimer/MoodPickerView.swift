//
//  MoodPickerView.swift
//  FocusTimer
//
//  Pre-session mood and energy picker

import Foundation
import Combine
import SwiftUI

struct MoodPickerView: View {
    @StateObject private var moodManager = MoodEnergyManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: (MoodEnergyEntry) -> Void
    
    @State private var selectedMood: FocusMood = .good
    @State private var selectedEnergy: EnergyLevel = .medium
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("How are you feeling?")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Your mood can affect how you focus today.")
                            .font(.caption)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.top, 20)
                    
                    // Mood selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mood")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            ForEach(FocusMood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    onTap: { selectedMood = mood }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Energy selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Energy Level")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(EnergyLevel.allCases, id: \.self) { energy in
                                EnergyButton(
                                    energy: energy,
                                    isSelected: selectedEnergy == energy,
                                    onTap: { selectedEnergy = energy }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Insight card
                    if let insight = getMoodInsight() {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text(insight)
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color(hex: "2C2C2E"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Continue button
                    Button(action: startSession) {
                        Text("Start Focusing")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "FF6B6B"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "8E8E93"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func getMoodInsight() -> String? {
        let corr = moodManager.getMoodCorrelation()
        guard !corr.isEmpty else { return nil }
        
        if let best = corr.max(by: { $0.value < $1.value }), best.value > 0.7 {
            return "You complete \(Int(best.value * 100))% of sessions when feeling \(best.key.lowercased())!"
        }
        return nil
    }
    
    private func startSession() {
        let entry = moodManager.logMoodEnergy(mood: selectedMood, energy: selectedEnergy)
        onComplete(entry)
        dismiss()
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: FocusMood
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 36))
                
                Text(mood.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FF6B6B").opacity(0.3) : Color(hex: "2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "FF6B6B") : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Energy Button

struct EnergyButton: View {
    let energy: EnergyLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: energy.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(hex: "FFD60A") : Color(hex: "8E8E93"))
                
                Text(energy.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FFD60A").opacity(0.2) : Color(hex: "2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "FFD60A") : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Mood Statistics View

struct MoodStatsView: View {
    @StateObject private var moodManager = MoodEnergyManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Today's mood distribution
            if !moodManager.todayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Moods")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        ForEach(FocusMood.allCases, id: \.self) { mood in
                            let count = moodManager.todayEntries.filter { $0.mood == mood }.count
                            MoodMiniStat(mood: mood, count: count)
                        }
                    }
                }
            }
            
            // Mood correlation insight
            if let insight = moodManager.getMoodInsight() {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text(insight)
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(12)
            }
            
            // Completion rate
            let rate = moodManager.getAverageCompletionRate()
            if rate > 0 {
                HStack {
                    Text("Session Completion")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    Spacer()
                    
                    Text("\(Int(rate * 100))%")
                        .font(.subheadline.bold())
                        .foregroundColor(rate > 0.7 ? Color(hex: "4ECB71") : Color(hex: "FF9500"))
                }
            }
        }
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
    }
}

struct MoodMiniStat: View {
    let mood: FocusMood
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text(mood.emoji)
                .font(.title3)
            
            Text("\(count)")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(count > 0 ? Color(hex: "2C2C2E") : Color.clear)
        .cornerRadius(8)
    }
}
