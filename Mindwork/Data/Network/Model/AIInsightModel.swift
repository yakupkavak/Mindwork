//
//  AnalysisModel.swift
//  Mindwork
//
//  Created by Yakup Kavak on 3.01.2026.
//

import Foundation
import FirebaseFirestore

struct AIInsightModel: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let message: String
    let patternType: String?      // e.g., "Impulsive", "Steady Flow"
    let focusScore: Int?          // 0-100
    let actionableTip: String?    // Specific advice
    let improvementStat: String?  // e.g., "15% Faster"
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "user_notification_title"
        case message = "user_notification_body"
        case patternType = "riskLevel" // Mapping legacy name to new concept
        case focusScore
        case actionableTip
        case improvementStat
        case createdAt
    }
} 
