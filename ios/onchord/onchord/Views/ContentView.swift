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
        VStack {
            if authManager.isSignedIn {
                TabBarView()
            } else {
                VStack(spacing: 20) {
                    Text("Welcome to Onchord")
                        .font(.title)

                    if authManager.isLoading {
                        ProgressView("Signing in...")
                    } else {
                        Button("Sign in with Spotify") {
                            authManager.login()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .environmentObject(authManager)
    }
}
