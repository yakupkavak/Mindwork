//
//  ViewExtension.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 8.10.2025.
//

import Foundation
import SwiftUI

extension View {
    func getRect() -> CGRect {
        UIScreen.main.bounds
    }
}

struct Colors {
    static let background = Color("background_color")
    static let selectedButton = Color("selected_button")
    static let unselectedButton = Color("unselected_button")

}
