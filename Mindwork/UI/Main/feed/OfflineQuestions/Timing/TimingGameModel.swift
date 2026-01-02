//
//  TimingGameModel.swift
//  Mindwork
//
//  Created by Cemre Bayer on 2.01.2026.
//
import SwiftUI

enum TimingResult: String {
    case perfect = "Harika!"
    case good = "Güzel"
    case miss = "Kaçırdın!"
    
    var color: Color {
        switch self {
        case .perfect: return .green
        case .good: return .orange
        case .miss: return .red
        }
    }
}
