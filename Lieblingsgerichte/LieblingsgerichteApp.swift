//
//  LieblingsgerichteApp.swift
//  Lieblingsgerichte
//
//  Created by Arthur Wunder on 25.10.24.
//

import SwiftUI

@main
struct LieblingsgerichteApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
