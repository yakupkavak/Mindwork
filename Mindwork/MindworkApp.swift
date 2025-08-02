//
//  MindworkApp.swift
//  Mindwork
//
//  Created by Yakup Kavak on 2.08.2025.
//

import SwiftUI

@main
struct MindworkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
