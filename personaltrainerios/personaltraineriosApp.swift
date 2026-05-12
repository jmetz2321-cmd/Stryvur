//
//  personaltraineriosApp.swift
//  personaltrainerios
//
//  Created by Jon Metz on 5/7/26.
//

import SwiftUI

@main
struct personaltraineriosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.requestPermission()
                }
        }
    }
}
