//
//  personaltraineriosApp.swift
//  personaltrainerios
//
//  Created by Jon Metz on 5/7/26.
//

import SwiftUI

@main
struct personaltraineriosApp: App {
    init() {
        // Install notification delegate before any view loads so cold-launch taps are captured.
        _ = NotificationCoordinator.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if !targetEnvironment(simulator)
                    NotificationManager.requestPermission()
                    #endif
                }
        }
    }
}
