//
//  onchordApp.swift
//  onchord
//
//  Created by Elodie Collier on 2/18/26.
//

import SwiftUI
import FirebaseCore

@main
struct onchordApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
            FirebaseApp.configure()
        }
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .preferredColorScheme(.dark)
            }
        }
}
