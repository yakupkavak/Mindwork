//
//  HistoryViewModel.swift
//  Tendria
//
//  Created by Yakup Kavak on 2.02.2025.
//

import Foundation

import FirebaseFirestore

struct ActivityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum StatsRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    var id: String { rawValue }
}

struct Badge: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let earned: Bool
}

struct CategoryProgress: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let progress: Double // 0...1
    let levelXP: (current: Int, max: Int)
}

struct GameStats: Identifiable {
    let id = UUID()
    let name: String
    let successRate: Double   // 0...1
    let avgTime: Int          // dakika
}

// MARK: - ViewModel (mock verilerle)

final class StatsViewModel: ObservableObject {
    @Published var selected: StatsRange = .today
    @Published private(set) var series: [ActivityPoint] = []
    @Published private(set) var badges: [Badge] = []
    @Published private(set) var categories: [CategoryProgress] = []
    @Published private(set) var games: [GameStats] = []
    
    // Özet metrikler
    @Published var totalMinutes: Int = 12
    @Published var successRate: Double = 0.76
    @Published var goalDone: Bool = true
    @Published var levelXP: (current: Int, max: Int) = (190, 200)
    
    init() {
        load(for: .today)
        badges = [
            .init(systemImage: "flame.fill",  title: "Streak",  earned: true),
            .init(systemImage: "target",      title: "Focus",   earned: true),
            .init(systemImage: "hare.fill",   title: "Speed",   earned: false),
            .init(systemImage: "trophy.fill", title: "Winner",  earned: true)
        ]
        categories = [
            .init(name: "Memory",       icon: "brain.head.profile", progress: 0.72, levelXP: (86, 120)),
            .init(name: "Focus",        icon: "scope",              progress: 0.64, levelXP: (77, 120)),
            .init(name: "Place & Time", icon: "clock",              progress: 0.45, levelXP: (54, 120))
        ]
        games = [
            .init(name: "Which One is Different", successRate: 0.82, avgTime: 5),
            .init(name: "Colorful Words", successRate: 0.71, avgTime: 7),
            .init(name: "Catch Number", successRate: 0.65, avgTime: 4)
        ]
    }
    
    func load(for range: StatsRange) {
        selected = range
        
        switch range {
        case .today:
            series = Self.mockHourly()
            totalMinutes = 12
            successRate = 0.76
            goalDone = true
            levelXP = (190, 200)
        case .week:
            series = Self.mockDaily(count: 7)
            totalMinutes = 60
            successRate = 0.59
            goalDone = true
            levelXP = (190, 200)
        case .month:
            series = Self.mockDaily(count: 30)
            totalMinutes = 635
            successRate = 0.62
            goalDone = true
            levelXP = (190, 200)
        }
    }
    
    // MARK: Mock data generators
    private static func mockHourly() -> [ActivityPoint] {
        let now = Date()
        return (0..<12).map { i in
            ActivityPoint(
                date: Calendar.current.date(byAdding: .hour, value: -11 + i, to: now)!,
                value: Double(Int.random(in: 2...10))
            )
        }
    }
    private static func mockDaily(count: Int) -> [ActivityPoint] {
        let now = Date()
        return (0..<count).map { i in
            ActivityPoint(
                date: Calendar.current.date(byAdding: .day, value: -(count-1) + i, to: now)!,
                value: Double(Int.random(in: 4...16))
            )
        }
    }
}
