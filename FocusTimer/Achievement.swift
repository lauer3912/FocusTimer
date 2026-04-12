//
//  Achievement.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - Achievement Badge

struct AchievementBadge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let icon: String
    let requirement: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case consistency = "consistency"
        case volume = "volume"
        case variety = "variety"
        case social = "social"
        case secret = "secret"
        case milestone = "milestone"
        case special = "special"
        
        var displayName: String {
            switch self {
            case .consistency: return "Consistency"
            case .volume: return "Volume"
            case .variety: return "Variety"
            case .social: return "Social"
            case .secret: return "Secret"
            case .milestone: return "Milestone"
            case .special: return "Special"
            }
        }
        
        var icon: String {
            switch self {
            case .consistency: return "flame.fill"
            case .volume: return "chart.bar.fill"
            case .variety: return "sparkles"
            case .social: return "person.2.fill"
            case .secret: return "questionmark.circle.fill"
            case .milestone: return "star.fill"
            case .special: return "gift.fill"
            }
        }
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var badges: [AchievementBadge] = []
    @Published var totalUnlocked: Int = 0
    
    init() {
        createAllAchievements()
        load()
    }
    
    private func createAllAchievements() {
        badges = [
            // === CONSISTENCY BADGES (7) ===
            AchievementBadge(id: "streak_3", name: "First Steps", description: "Complete 3 day streak", category: .consistency, icon: "flame", requirement: 3),
            AchievementBadge(id: "streak_7", name: "Week Warrior", description: "Complete 7 day streak", category: .consistency, icon: "flame.fill", requirement: 7),
            AchievementBadge(id: "streak_14", name: "Fortnight Focus", description: "Complete 14 day streak", category: .consistency, icon: "flame.fill", requirement: 14),
            AchievementBadge(id: "streak_30", name: "Monthly Master", description: "Complete 30 day streak", category: .consistency, icon: "flame.fill", requirement: 30),
            AchievementBadge(id: "streak_60", name: "Two Month Titan", description: "Complete 60 day streak", category: .consistency, icon: "flame.fill", requirement: 60),
            AchievementBadge(id: "streak_100", name: "Century Club", description: "Complete 100 day streak", category: .consistency, icon: "flame.fill", requirement: 100),
            AchievementBadge(id: "streak_365", name: "Year of Focus", description: "Complete 365 day streak", category: .consistency, icon: "crown.fill", requirement: 365),
            
            // === VOLUME BADGES (20) ===
            AchievementBadge(id: "sessions_10", name: "Getting Started", description: "Complete 10 focus sessions", category: .volume, icon: "circle.fill", requirement: 10),
            AchievementBadge(id: "sessions_25", name: "Quarter Century", description: "Complete 25 focus sessions", category: .volume, icon: "circle.fill", requirement: 25),
            AchievementBadge(id: "sessions_50", name: "Half Century", description: "Complete 50 focus sessions", category: .volume, icon: "circle.fill", requirement: 50),
            AchievementBadge(id: "sessions_100", name: "Centurion", description: "Complete 100 focus sessions", category: .volume, icon: "star.fill", requirement: 100),
            AchievementBadge(id: "sessions_250", name: "Silver Session", description: "Complete 250 focus sessions", category: .volume, icon: "star.fill", requirement: 250),
            AchievementBadge(id: "sessions_500", name: "Productivity Pro", description: "Complete 500 focus sessions", category: .volume, icon: "star.fill", requirement: 500),
            AchievementBadge(id: "sessions_750", name: "Gold Focus", description: "Complete 750 focus sessions", category: .volume, icon: "star.circle.fill", requirement: 750),
            AchievementBadge(id: "sessions_1000", name: "Focus Legend", description: "Complete 1,000 focus sessions", category: .volume, icon: "crown.fill", requirement: 1000),
            AchievementBadge(id: "sessions_2500", name: "Platinum Focus", description: "Complete 2,500 focus sessions", category: .volume, icon: "crown.fill", requirement: 2500),
            AchievementBadge(id: "sessions_5000", name: "Focus Immortal", description: "Complete 5,000 focus sessions", category: .volume, icon: "crown.fill", requirement: 5000),
            
            // Hours badges
            AchievementBadge(id: "hours_5", name: "5 Hour Starter", description: "Focus for 5 total hours", category: .volume, icon: "clock.fill", requirement: 5),
            AchievementBadge(id: "hours_10", name: "10 Hour Club", description: "Focus for 10 total hours", category: .volume, icon: "clock.fill", requirement: 10),
            AchievementBadge(id: "hours_25", name: "25 Hour Milestone", description: "Focus for 25 total hours", category: .volume, icon: "clock.fill", requirement: 25),
            AchievementBadge(id: "hours_50", name: "50 Hour Club", description: "Focus for 50 total hours", category: .volume, icon: "clock.fill", requirement: 50),
            AchievementBadge(id: "hours_100", name: "100 Hour Club", description: "Focus for 100 total hours", category: .volume, icon: "clock.fill", requirement: 100),
            AchievementBadge(id: "hours_250", name: "250 Hour Elite", description: "Focus for 250 total hours", category: .volume, icon: "clock.badge.checkmark.fill", requirement: 250),
            AchievementBadge(id: "hours_500", name: "500 Hour Master", description: "Focus for 500 total hours", category: .volume, icon: "clock.badge.checkmark.fill", requirement: 500),
            AchievementBadge(id: "hours_1000", name: "1000 Hour Legend", description: "Focus for 1,000 total hours", category: .volume, icon: "clock.badge.checkmark.fill", requirement: 1000),
            
            // === VARIETY BADGES (15) ===
            AchievementBadge(id: "modes_all", name: "Mode Explorer", description: "Try all focus modes", category: .variety, icon: "sparkles", requirement: 6),
            AchievementBadge(id: "modes_deep_10", name: "Deep Diver", description: "Complete 10 Deep Work sessions", category: .variety, icon: "brain.head.profile", requirement: 10),
            AchievementBadge(id: "modes_deep_50", name: "Deep Master", description: "Complete 50 Deep Work sessions", category: .variety, icon: "brain.head.profile", requirement: 50),
            AchievementBadge(id: "modes_creative_10", name: "Creative Spirit", description: "Complete 10 Creative Flow sessions", category: .variety, icon: "paintbrush.fill", requirement: 10),
            AchievementBadge(id: "modes_creative_50", name: "Creative Master", description: "Complete 50 Creative Flow sessions", category: .variety, icon: "paintbrush.fill", requirement: 50),
            AchievementBadge(id: "modes_mini_10", name: "Mini Master", description: "Complete 10 Mini Sprint sessions", category: .variety, icon: "hare.fill", requirement: 10),
            AchievementBadge(id: "modes_marathon_5", name: "Marathon Runner", description: "Complete 5 Marathon sessions", category: .variety, icon: "figure.run", requirement: 5),
            AchievementBadge(id: "labels_3", name: "Label Lister", description: "Use 3 different session labels", category: .variety, icon: "tag.fill", requirement: 3),
            AchievementBadge(id: "labels_5", name: "Organizer", description: "Use 5 different session labels", category: .variety, icon: "tag.fill", requirement: 5),
            AchievementBadge(id: "labels_all", name: "Label Master", description: "Use all session labels", category: .variety, icon: "tag.fill", requirement: 8),
            AchievementBadge(id: "sounds_3", name: "Sound Scout", description: "Try 3 different focus sounds", category: .variety, icon: "headphones", requirement: 3),
            AchievementBadge(id: "sounds_5", name: "Audiophile", description: "Try 5 different focus sounds", category: .variety, icon: "headphones", requirement: 5),
            AchievementBadge(id: "sounds_all", name: "Sound Collector", description: "Try all focus sounds", category: .variety, icon: "headphones", requirement: 12),
            AchievementBadge(id: "challenges_10", name: "Challenge Seeker", description: "Complete 10 daily challenges", category: .variety, icon: "star.fill", requirement: 10),
            AchievementBadge(id: "challenges_50", name: "Challenge Champion", description: "Complete 50 daily challenges", category: .variety, icon: "trophy.fill", requirement: 50),
            AchievementBadge(id: "challenges_100", name: "Challenge Legend", description: "Complete 100 daily challenges", category: .variety, icon: "trophy.fill", requirement: 100),
            
            // === MILESTONE BADGES (15) ===
            AchievementBadge(id: "first_session", name: "First Focus", description: "Complete your first focus session", category: .milestone, icon: "play.fill", requirement: 1),
            AchievementBadge(id: "first_day_goal", name: "Goal Getter", description: "Hit your daily goal", category: .milestone, icon: "target", requirement: 1),
            AchievementBadge(id: "first_streak", name: "Streak Starter", description: "Start a 3-day streak", category: .milestone, icon: "flame", requirement: 3),
            AchievementBadge(id: "first_xp", name: "XP Hunter", description: "Earn your first 100 XP", category: .milestone, icon: "sparkles", requirement: 100),
            AchievementBadge(id: "first_hour", name: "Hour One", description: "Focus for your first hour", category: .milestone, icon: "clock", requirement: 1),
            AchievementBadge(id: "level_5", name: "Rising Star", description: "Reach level 5", category: .milestone, icon: "star.fill", requirement: 5),
            AchievementBadge(id: "level_10", name: "Focus Apprentice", description: "Reach level 10", category: .milestone, icon: "star.fill", requirement: 10),
            AchievementBadge(id: "level_15", name: "Focus Adept", description: "Reach level 15", category: .milestone, icon: "star.fill", requirement: 15),
            AchievementBadge(id: "level_20", name: "Focus Specialist", description: "Reach level 20", category: .milestone, icon: "star.circle", requirement: 20),
            AchievementBadge(id: "level_25", name: "Focus Expert", description: "Reach level 25", category: .milestone, icon: "star.circle.fill", requirement: 25),
            AchievementBadge(id: "level_30", name: "Focus Virtuoso", description: "Reach level 30", category: .milestone, icon: "star.circle.fill", requirement: 30),
            AchievementBadge(id: "level_40", name: "Focus Elite", description: "Reach level 40", category: .milestone, icon: "crown", requirement: 40),
            AchievementBadge(id: "level_50", name: "Focus Master", description: "Reach level 50", category: .milestone, icon: "crown.fill", requirement: 50),
            AchievementBadge(id: "level_75", name: "Focus Grandmaster", description: "Reach level 75", category: .milestone, icon: "crown.fill", requirement: 75),
            AchievementBadge(id: "level_100", name: "Focus Legend", description: "Reach level 100", category: .milestone, icon: "crown.fill", requirement: 100),
            
            // === SPECIAL BADGES (20) ===
            AchievementBadge(id: "marathon_first", name: "Marathon Debut", description: "Complete your first Marathon session", category: .special, icon: "figure.run", requirement: 1),
            AchievementBadge(id: "marathon_5", name: "Marathon Finisher", description: "Complete 5 Marathon sessions", category: .special, icon: "figure.run", requirement: 5),
            AchievementBadge(id: "queue_3", name: "Queue Starter", description: "Complete a queue with 3+ sessions", category: .special, icon: "list.bullet.rectangle", requirement: 3),
            AchievementBadge(id: "queue_5", name: "Queue Master", description: "Complete a queue with 5+ sessions", category: .special, icon: "list.bullet.rectangle", requirement: 5),
            AchievementBadge(id: "queue_10", name: "Queue Champion", description: "Complete a queue with 10+ sessions", category: .special, icon: "list.bullet.rectangle.fill", requirement: 10),
            AchievementBadge(id: "perfect_day", name: "Perfect Day", description: "Complete daily goal with no abandoned sessions", category: .special, icon: "checkmark.seal.fill", requirement: 1),
            AchievementBadge(id: "perfect_week", name: "Perfect Week", description: "7 perfect days in a row", category: .special, icon: "checkmark.seal.fill", requirement: 7),
            AchievementBadge(id: "early_bird_3", name: "Early Bird", description: "Complete 3 sessions before 9 AM", category: .special, icon: "sunrise.fill", requirement: 3),
            AchievementBadge(id: "early_bird_10", name: "Morning Champion", description: "Complete 10 sessions before 9 AM", category: .special, icon: "sunrise.fill", requirement: 10),
            AchievementBadge(id: "night_owl", name: "Night Owl", description: "Complete a session after 10 PM", category: .special, icon: "moon.fill", requirement: 1),
            AchievementBadge(id: "night_owl_10", name: "Midnight Master", description: "Complete 10 sessions after 10 PM", category: .special, icon: "moon.fill", requirement: 10),
            AchievementBadge(id: "weekend_warrior", name: "Weekend Warrior", description: "Complete 10 sessions on weekends", category: .special, icon: "calendar", requirement: 10),
            AchievementBadge(id: "weekend_25", name: "Weekend Legend", description: "Complete 25 sessions on weekends", category: .special, icon: "calendar.badge.checkmark", requirement: 25),
            AchievementBadge(id: "coin_collector", name: "Coin Collector", description: "Earn 1,000 Focus Coins", category: .special, icon: "bitcoinsign.circle.fill", requirement: 1000),
            AchievementBadge(id: "coin_hoarder", name: "Coin Hoarder", description: "Earn 5,000 Focus Coins", category: .special, icon: "bitcoinsign.circle.fill", requirement: 5000),
            AchievementBadge(id: "coin_millionaire", name: "Coin Millionaire", description: "Earn 10,000 Focus Coins", category: .special, icon: "bitcoinsign.circle.fill", requirement: 10000),
            AchievementBadge(id: "project_5", name: "Project Starter", description: "Create 5 projects", category: .special, icon: "folder.fill", requirement: 5),
            AchievementBadge(id: "project_10", name: "Project Master", description: "Create 10 projects", category: .special, icon: "folder.fill", requirement: 10),
            AchievementBadge(id: "daily_7", name: "Week Tracker", description: "Use daily planner for 7 days", category: .special, icon: "calendar.badge.clock", requirement: 7),
            AchievementBadge(id: "daily_30", name: "Month Planner", description: "Use daily planner for 30 days", category: .special, icon: "calendar.badge.clock", requirement: 30),
            
            // === SOCIAL BADGES (10) ===
            AchievementBadge(id: "share_1", name: "Sharer", description: "Share your progress once", category: .social, icon: "square.and.arrow.up", requirement: 1),
            AchievementBadge(id: "share_10", name: "Social Star", description: "Share your progress 10 times", category: .social, icon: "square.and.arrow.up.fill", requirement: 10),
            AchievementBadge(id: "share_50", name: "Influencer", description: "Share your progress 50 times", category: .social, icon: "star.square.fill", requirement: 50),
            AchievementBadge(id: "invite_1", name: "Friend Maker", description: "Invite your first friend", category: .social, icon: "person.badge.plus", requirement: 1),
            AchievementBadge(id: "invite_5", name: "Community Builder", description: "Invite 5 friends", category: .social, icon: "person.2.fill", requirement: 5),
            AchievementBadge(id: "buddy_focus_1", name: "Focus Buddy", description: "Focus alongside a buddy", category: .social, icon: "person.2.circle.fill", requirement: 1),
            AchievementBadge(id: "buddy_focus_10", name: "Accountability Partner", description: "Focus with buddies 10 times", category: .social, icon: "person.3.fill", requirement: 10),
            AchievementBadge(id: "leaderboard_1", name: "First Place", description: "Top the weekly leaderboard", category: .social, icon: "trophy.fill", requirement: 1),
            AchievementBadge(id: "leaderboard_5", name: "Champion", description: "Top the leaderboard 5 times", category: .social, icon: "trophy.fill", requirement: 5),
            AchievementBadge(id: "duel_win_1", name: "First Duel", description: "Win your first focus duel", category: .social, icon: "bolt.fill", requirement: 1),
            
            // === SECRET BADGES (10) ===
            AchievementBadge(id: "secret_focuser", name: "???", description: "Focus during all phases of the moon", category: .secret, icon: "moon.stars.fill", requirement: 1),
            AchievementBadge(id: "secret_rain", name: "???", description: "Complete 10 sessions while it rains", category: .secret, icon: "cloud.rain.fill", requirement: 10),
            AchievementBadge(id: "secret_perfectionist", name: "???", description: "100 perfect days", category: .secret, icon: "star.circle.fill", requirement: 100),
            AchievementBadge(id: "secret_early_early", name: "???", description: "Session at 4 AM", category: .secret, icon: "clock.fill", requirement: 1),
            AchievementBadge(id: "secret_marathon_mystery", name: "???", description: "Marathon during a full moon", category: .secret, icon: "figure.run", requirement: 1),
            AchievementBadge(id: "secret_all_sounds", name: "???", description: "Use every sound in one day", category: .secret, icon: "speaker.wave.3.fill", requirement: 12),
            AchievementBadge(id: "secret_streak_streak", name: "???", description: "30-day streak during winter", category: .secret, icon: "snowflake", requirement: 30),
            AchievementBadge(id: "secret_multitasker", name: "???", description: "Complete 3 sessions while planning", category: .secret, icon: "checklist", requirement: 3),
            AchievementBadge(id: "secret_focus_master", name: "???", description: "Reach max focus score 7 days straight", category: .secret, icon: "brain.head.profile", requirement: 7),
            AchievementBadge(id: "secret_legend", name: "???", description: "Achieve all other secret badges", category: .secret, icon: "questionmark.circle.fill", requirement: 9),
            
            // === TIME-OF-DAY BADGES (10) ===
            AchievementBadge(id: "morning_50", name: "Morning Person", description: "Complete 50 morning sessions", category: .special, icon: "sun.max.fill", requirement: 50),
            AchievementBadge(id: "afternoon_50", name: "Afternoon Focus", description: "Complete 50 afternoon sessions", category: .special, icon: "sun.haze.fill", requirement: 50),
            AchievementBadge(id: "evening_50", name: "Evening Elite", description: "Complete 50 evening sessions", category: .special, icon: "sunset.fill", requirement: 50),
            AchievementBadge(id: "lunch_focus", name: "Lunch Breaker", description: "Complete a session during lunch (12-1)", category: .special, icon: "fork.knife", requirement: 1),
            AchievementBadge(id: "consecutive_same_time", name: "Routine Builder", description: "Same time focus for 7 days", category: .special, icon: "clock.badge.checkmark", requirement: 7),
            
            // === RECOVERY BADGES (5) ===
            AchievementBadge(id: "streak_back", name: "Streak Returner", description: "Recover a broken streak", category: .special, icon: "arrow.uturn.backward", requirement: 1),
            AchievementBadge(id: "comeback", name: "Comeback Kid", description: "Return after 7+ day break", category: .special, icon: "arrow.clockwise", requirement: 1),
            AchievementBadge(id: "never_give_up", name: "Never Give Up", description: "Return after 30+ day break", category: .special, icon: "heart.fill", requirement: 1),
            
            // === GRIND BADGES (8) ===
            AchievementBadge(id: "grind_10", name: "Grinder", description: "Complete 10 sessions in one day", category: .special, icon: "flame", requirement: 10),
            AchievementBadge(id: "grind_15", name: "Hard Worker", description: "Complete 15 sessions in one day", category: .special, icon: "flame.fill", requirement: 15),
            AchievementBadge(id: "grind_20", name: "Spartan", description: "Complete 20 sessions in one day", category: .special, icon: "flame.fill", requirement: 20),
            AchievementBadge(id: "minutes_500_day", name: "5 Hour Day", description: "Focus for 5 hours in one day", category: .special, icon: "clock.fill", requirement: 300),
            AchievementBadge(id: "minutes_600_day", name: "10 Hour Day", description: "Focus for 10 hours in one day", category: .special, icon: "clock.fill", requirement: 600),
            AchievementBadge(id: "no_break_5", name: "No Breaks", description: "Complete 5 sessions without breaking", category: .special, icon: "forward.fill", requirement: 5),
            AchievementBadge(id: "no_break_10", name: "Breakless", description: "Complete 10 sessions without breaking", category: .special, icon: "forward.fill", requirement: 10),
            AchievementBadge(id: "theme_all", name: "Theme Collector", description: "Use all 10 themes", category: .special, icon: "paintpalette.fill", requirement: 10),
        ]
    }
    
    func checkAndUnlockAchievements(stats: FocusStatistics, extra: [String: Int]) {
        for i in 0..<badges.count {
            guard !badges[i].isUnlocked else { continue }
            
            var progress = 0
            
            switch badges[i].category {
            case .consistency:
                progress = stats.currentStreak
            case .volume:
                if badges[i].id.contains("sessions") {
                    progress = stats.totalSessions
                } else if badges[i].id.contains("hours") {
                    progress = stats.totalMinutes / 60
                }
            case .milestone:
                if badges[i].id.contains("level") {
                    progress = extra["level"] ?? 0
                } else if badges[i].id.contains("xp") {
                    progress = extra["totalXP"] ?? 0
                } else {
                    progress = stats.totalSessions > 0 ? 1 : 0
                }
            case .variety:
                progress = extra["modesUsed"] ?? 0
            case .special:
                progress = extra[badges[i].id] ?? 0
            default:
                continue
            }
            
            if progress >= badges[i].requirement {
                badges[i].isUnlocked = true
                badges[i].unlockedDate = Date()
                totalUnlocked += 1
            }
        }
        save()
    }
    
    func getUnlockedBadges() -> [AchievementBadge] {
        badges.filter { $0.isUnlocked }
    }
    
    func getLockedBadges() -> [AchievementBadge] {
        badges.filter { !$0.isUnlocked }
    }
    
    func getBadgesByCategory(_ category: AchievementBadge.AchievementCategory) -> [AchievementBadge] {
        badges.filter { $0.category == category }
    }
    
    func getProgress(for badgeId: String) -> Double {
        guard let badge = badges.first(where: { $0.id == badgeId }) else { return 0 }
        // This would be calculated based on current stats
        return 0.0 // Simplified for now
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        UserDefaults.standard.set(totalUnlocked, forKey: "achievements_unlocked")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([AchievementBadge].self, from: data) {
            badges = decoded
            totalUnlocked = badges.filter { $0.isUnlocked }.count
        }
    }
}
