//
//  TimingModel.swift
//  Mindwork
//
//  Created by Sena Yıldız on 1.01.2026.
//

import SwiftUI

enum TimingResult: String {
    case perfect = "Mükemmel"
    case good = "Başarılı"
    case miss = "Başarısız"
    
    var color: Color {
        switch self {
        case .perfect: return .green
        case .good: return .orange
        case .miss: return .red
        }
    }
}
