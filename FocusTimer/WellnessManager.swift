//
//  WellnessManager.swift
//  FocusTimer
//
//  F63: Screen-Free Break Mode
import Foundation
import Combine
import SwiftUI
//  F66: Mental Load Manager
//  F57: Eye Care Reminders (20-20-20)
//  F56: Posture Break Alerts
//

import Foundation
import Combine
import UserNotifications

// MARK: - Mental Load Entry

struct MentalLoadEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let date: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.date = Date()
    }
}

// MARK: - Wellness Manager

class WellnessManager: ObservableObject {
    static let shared = WellnessManager()
    
    // Mental Load
    @Published var mentalLoadEntries: [MentalLoadEntry] = []
    @Published var showMentalLoadPrompt: Bool = false
    @Published var pendingThoughts: String = ""
    
    // Screen-Free Break
    @Published var isScreenFreeMode: Bool = false
    @Published var breakStartTime: Date?
    
    // Eye Care (20-20-20)
    @Published var eyeCareEnabled: Bool = false
    @Published var lastEyeBreakTime: Date = Date()
    @Published var showEyeCareReminder: Bool = false
    
    // Posture
    @Published var postureRemindersEnabled: Bool = false
    @Published var showPostureReminder: Bool = false
    @Published var postureBreakInterval: Int = 30 // minutes
    
    // Hydration
    @Published var hydrationRemindersEnabled: Bool = false
    @Published var lastHydrationTime: Date = Date()
    @Published var hydrationInterval: Int = 45 // minutes
    @Published var showHydrationReminder: Bool = false
    
    private var wellnessTimer: Timer?
    
    private init() {
        load()
    }
    
    // MARK: - Mental Load Manager
    
    func addMentalLoad(_ text: String) {
        let entry = MentalLoadEntry(text: text)
        mentalLoadEntries.append(entry)
        save()
    }
    
    func clearMentalLoad() {
        mentalLoadEntries = []
        save()
    }
    
    func getTodaysMentalLoad() -> [MentalLoadEntry] {
        let calendar = Calendar.current
        return mentalLoadEntries.filter { calendar.isDateInToday($0.date) }
    }
    
    func showMentalLoadPromptIfNeeded() {
        showMentalLoadPrompt = true
    }
    
    // MARK: - Screen-Free Break Mode
    
    func startScreenFreeBreak(from time: Date) {
        isScreenFreeMode = true
        breakStartTime = time
    }
    
    func endScreenFreeBreak() {
        isScreenFreeMode = false
        breakStartTime = nil
    }
    
    var screenFreeBreakDuration: Int {
        guard let start = breakStartTime else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }
    
    var formattedScreenFreeDuration: String {
        let minutes = screenFreeBreakDuration / 60
        let seconds = screenFreeBreakDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Eye Care (20-20-20)
    
    func enableEyeCare(_ enabled: Bool) {
        eyeCareEnabled = enabled
        if enabled {
            scheduleEyeCareReminders()
        } else {
            cancelEyeCareReminders()
        }
        save()
    }
    
    func recordEyeBreak() {
        lastEyeBreakTime = Date()
        showEyeCareReminder = false
    }
    
    private func scheduleEyeCareReminders() {
        // Schedule a reminder every 20 minutes
        let content = UNMutableNotificationContent()
        content.title = "👀 Eye Break Time"
        content.body = "Look at something 20 feet away for 20 seconds"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20 * 60, repeats: true)
        let request = UNNotificationRequest(identifier: "eye_care_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelEyeCareReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eye_care_reminder"])
    }
    
    // MARK: - Posture Reminders
    
    func enablePostureReminders(_ enabled: Bool) {
        postureRemindersEnabled = enabled
        if enabled {
            schedulePostureReminders()
        } else {
            cancelPostureReminders()
        }
        save()
    }
    
    func recordPostureBreak() {
        showPostureReminder = false
    }
    
    private func schedulePostureReminders() {
        let content = UNMutableNotificationContent()
        content.title = "🧘 Posture Check"
        content.body = "Sit up straight! Roll your shoulders back."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(postureBreakInterval * 60), repeats: true)
        let request = UNNotificationRequest(identifier: "posture_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelPostureReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["posture_reminder"])
    }
    
    // MARK: - Hydration Reminders
    
    func enableHydrationReminders(_ enabled: Bool) {
        hydrationRemindersEnabled = enabled
        if enabled {
            scheduleHydrationReminders()
        } else {
            cancelHydrationReminders()
        }
        save()
    }
    
    func recordHydration() {
        lastHydrationTime = Date()
        showHydrationReminder = false
    }
    
    private func scheduleHydrationReminders() {
        let content = UNMutableNotificationContent()
        content.title = "💧 Stay Hydrated"
        content.body = "Take a sip of water!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hydrationInterval * 60), repeats: true)
        let request = UNNotificationRequest(identifier: "hydration_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelHydrationReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["hydration_reminder"])
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(mentalLoadEntries) {
            UserDefaults.standard.set(encoded, forKey: "mental_load_entries")
        }
        UserDefaults.standard.set(eyeCareEnabled, forKey: "eye_care_enabled")
        UserDefaults.standard.set(postureRemindersEnabled, forKey: "posture_reminders_enabled")
        UserDefaults.standard.set(hydrationRemindersEnabled, forKey: "hydration_reminders_enabled")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "mental_load_entries"),
           let decoded = try? JSONDecoder().decode([MentalLoadEntry].self, from: data) {
            mentalLoadEntries = decoded
        }
        eyeCareEnabled = UserDefaults.standard.bool(forKey: "eye_care_enabled")
        postureRemindersEnabled = UserDefaults.standard.bool(forKey: "posture_reminders_enabled")
        hydrationRemindersEnabled = UserDefaults.standard.bool(forKey: "hydration_reminders_enabled")
    }
    
    func resetIfNewDay() {
        // Keep mental load entries but filter old ones
        let calendar = Calendar.current
        mentalLoadEntries = mentalLoadEntries.filter { calendar.isDateInToday($0.date) }
        save()
    }
}

// MARK: - Screen-Free Break View

struct ScreenFreeBreakView: View {
    @StateObject private var wellness = WellnessManager.shared
    @StateObject private var timerManager = TimerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Deep dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Rest message
                VStack(spacing: 16) {
                    Text("🌿")
                        .font(.system(size: 64))
                    
                    Text("Screen-Free Break")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("Put down your phone and rest your eyes")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Break timer
                VStack(spacing: 8) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 72, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("BREAK TIME")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                        .tracking(4)
                }
                
                Spacer()
                
                // Break suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    BreakSuggestion(icon: "👀", text: "Look at something 20 feet away")
                    BreakSuggestion(icon: "💧", text: "Take a sip of water")
                    BreakSuggestion(icon: "🧘", text: "Take 3 deep breaths")
                    BreakSuggestion(icon: "👃", text: "Stretch your neck and shoulders")
                }
                .padding()
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // End break button
                Button(action: endBreak) {
                    Text("End Break")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 48)
                        .background(Color(hex: "FF6B6B"))
                        .cornerRadius(30)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            wellness.startScreenFreeBreak(from: Date())
        }
    }
    
    private func endBreak() {
        wellness.endScreenFreeBreak()
        dismiss()
    }
}

struct BreakSuggestion: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Mental Load View

struct MentalLoadView: View {
    @StateObject private var wellness = WellnessManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var thoughtText: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🧠")
                            .font(.system(size: 48))
                        
                        Text("Mental Load")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Write down anything that's on your mind so you can let it go and focus.")
                            .font(.caption)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's distracting you?")
                            .font(.caption)
                            .foregroundColor(Color(hex: "8E8E93"))
                        
                        TextEditor(text: $thoughtText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Previous thoughts
                    if !wellness.getTodaysMentalLoad().isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Thoughts")
                                .font(.caption)
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(wellness.getTodaysMentalLoad()) { entry in
                                        HStack {
                                            Text(entry.text)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "4ECB71"))
                                        }
                                        .padding(12)
                                        .background(Color(hex: "2C2C2E"))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: saveAndDismiss) {
                            Text("Add & Start Focusing")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(thoughtText.isEmpty ? Color(hex: "3A3A3C") : Color(hex: "FF6B6B"))
                                .cornerRadius(12)
                        }
                        .disabled(thoughtText.isEmpty)
                        
                        Button(action: { dismiss() }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveAndDismiss() {
        if !thoughtText.isEmpty {
            wellness.addMentalLoad(thoughtText)
        }
        dismiss()
    }
}

// MARK: - Wellness Settings View

struct WellnessSettingsView: View {
    @StateObject private var wellness = WellnessManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                List {
                    Section {
                        Toggle(isOn: Binding(
                            get: { wellness.eyeCareEnabled },
                            set: { wellness.enableEyeCare($0) }
                        )) {
                            HStack {
                                Text("👀")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Eye Care Reminders")
                                        .foregroundColor(.white)
                                    Text("20-20-20 rule every 20 min")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .tint(Color(hex: "4ECB71"))
                        
                        Toggle(isOn: Binding(
                            get: { wellness.postureRemindersEnabled },
                            set: { wellness.enablePostureReminders($0) }
                        )) {
                            HStack {
                                Text("🧘")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Posture Reminders")
                                        .foregroundColor(.white)
                                    Text("Periodic posture check alerts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .tint(Color(hex: "4ECB71"))
                        
                        Toggle(isOn: Binding(
                            get: { wellness.hydrationRemindersEnabled },
                            set: { wellness.enableHydrationReminders($0) }
                        )) {
                            HStack {
                                Text("💧")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Hydration Reminders")
                                        .foregroundColor(.white)
                                    Text("Regular water intake prompts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .tint(Color(hex: "4ECB71"))
                    } header: {
                        Text("Wellness")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "2C2C2E"))
                    
                    Section {
                        NavigationLink {
                            MentalLoadHistoryView()
                        } label: {
                            HStack {
                                Text("🧠")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Mental Load History")
                                        .foregroundColor(.white)
                                    Text("\(wellness.getTodaysMentalLoad().count) thoughts captured today")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } header: {
                        Text("Mental Health")
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "2C2C2E"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Wellness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MentalLoadHistoryView: View {
    @StateObject private var wellness = WellnessManager.shared
    
    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()
            
            if wellness.mentalLoadEntries.isEmpty {
                VStack(spacing: 16) {
                    Text("🧠")
                        .font(.system(size: 48))
                    Text("No thoughts captured yet")
                        .foregroundColor(.gray)
                }
            } else {
                List {
                    ForEach(wellness.mentalLoadEntries.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.text)
                                .foregroundColor(.white)
                            
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(hex: "2C2C2E"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Mental Load History")
    }
}
