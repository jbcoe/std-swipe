//
//  std_swipeApp.swift
//  std-swipe
//
//  Created by Jonathan Coe on 27/03/2026.
//

import SwiftUI
import CoreData

@main
struct std_swipeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
