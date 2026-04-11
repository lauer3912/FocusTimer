//
//  ProjectTracking.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - Project

struct FocusProject: Codable, Identifiable {
    let id: UUID
    var name: String
    var color: String
    var sessions: Int = 0
    var totalMinutes: Int = 0
    var createdDate: Date
    var isArchived: Bool = false
    
    var formattedTime: String {
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Project Manager

class ProjectManager: ObservableObject {
    static let shared = ProjectManager()
    
    @Published var projects: [FocusProject] = []
    @Published var activeProjectId: UUID?
    
    var activeProject: FocusProject? {
        guard let id = activeProjectId else { return nil }
        return projects.first { $0.id == id }
    }
    
    var totalTrackedMinutes: Int {
        projects.reduce(0) { $0 + $1.totalMinutes }
    }
    
    func createProject(name: String, color: String) -> FocusProject {
        let project = FocusProject(
            id: UUID(),
            name: name,
            color: color,
            createdDate: Date()
        )
        projects.append(project)
        save()
        return project
    }
    
    func deleteProject(_ project: FocusProject) {
        projects.removeAll { $0.id == project.id }
        if activeProjectId == project.id {
            activeProjectId = nil
        }
        save()
    }
    
    func archiveProject(_ project: FocusProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isArchived = true
        }
        save()
    }
    
    func logSession(minutes: Int) {
        guard let index = projects.firstIndex(where: { $0.id == activeProjectId }) else { return }
        projects[index].sessions += 1
        projects[index].totalMinutes += minutes
        save()
    }
    
    func setActiveProject(_ project: FocusProject?) {
        activeProjectId = project?.id
        save()
    }
    
    func getTopProjects(limit: Int = 5) -> [FocusProject] {
        projects.filter { !$0.isArchived }
               .sorted { $0.totalMinutes > $1.totalMinutes }
               .prefix(limit)
               .map { $0 }
    }
    
    func getWeeklyReport() -> [UUID: Int] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        var weekly: [UUID: Int] = [:]
        
        for project in projects {
            let weekMinutes = dataManager.sessions
                .filter { session in
                    session.type == .work &&
                    session.completed &&
                    session.startTime >= startOfWeek
                }
                .reduce(0) { $0 + $1.duration } / 60
            
            if weekMinutes > 0 {
                weekly[project.id] = weekMinutes
            }
        }
        
        return weekly
    }
    
    private var dataManager: FocusDataManager { FocusDataManager.shared }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "focus_projects")
        }
        if let id = activeProjectId {
            UserDefaults.standard.set(id.uuidString, forKey: "active_project_id")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "focus_projects"),
           let decoded = try? JSONDecoder().decode([FocusProject].self, from: data) {
            projects = decoded
        }
        if let idStr = UserDefaults.standard.string(forKey: "active_project_id"),
           let id = UUID(uuidString: idStr) {
            activeProjectId = id
        }
    }
}
