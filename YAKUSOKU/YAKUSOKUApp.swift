//
//  YAKUSOKUApp.swift
//  YAKUSOKU
//
//  Created by EUIHYUNG JUNG on 8/18/25.
//

import SwiftUI
import SwiftData

@main
struct YAKUSOKUApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try SharedContainer.container()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
