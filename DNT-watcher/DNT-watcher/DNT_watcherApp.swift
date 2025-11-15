//
//  DNT_watcherApp.swift
//  DNT-watcher
//
//  Created by Bjørn Hoxmark on 15/11/2025.
//

import SwiftUI
import SwiftData

@main
struct DNT_watcherApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cabin.self,
            AvailabilityHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Request notification permissions on startup
        Task {
            _ = await NotificationManager.shared.requestPermission()
        }

        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            CabinListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
