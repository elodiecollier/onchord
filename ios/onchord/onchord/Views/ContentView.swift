//
//  ContentView.swift
//  onchord
//
//  Created by Elodie Collier on 2/18/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isSignedIn {
                TabBarView()
            } else {
                SignInView()
            }
        }
        .environmentObject(authManager)
    }
}
