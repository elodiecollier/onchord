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
    init() {
            FirebaseApp.configure()
        }
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
}
