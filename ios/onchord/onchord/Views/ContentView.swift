//
//  ContentView.swift
//  onchord
//
//  Created by Elodie Collier on 2/18/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var status = "Not signed in"
    private let spotifyAuth = SpotifyAuth()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(status)
                .multilineTextAlignment(.center)
            
            Button("Sign in anonymously (dev)") {
                Auth.auth().signInAnonymously { _, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            status = "❌ Firebase auth error: \(error.localizedDescription)"
                        } else {
                            status = "✅ Signed in anonymously"
                        }
                    }
                }
            }
            Button("Refresh Spotify Token") {
                Task { await refreshSpotifyToken() }
            }
            Button("Connect Spotify") {
                spotifyAuth.startLogin { result in
                    switch result {
                    case .success(let payload):
                        Task {
                            await exchangeWithBackend(payload: payload)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            status = "❌ Spotify login error: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func exchangeWithBackend(
        payload: (code: String, codeVerifier: String, redirectUri: String)
    ) async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { status = "❌ Not signed into Firebase" }
                return
            }
            
            let idToken = try await user.getIDToken()
            
            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyExchange")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "code": payload.code,
                "codeVerifier": payload.codeVerifier,
                "redirectUri": payload.redirectUri
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1
            let json = String(data: data, encoding: .utf8) ?? "nil"
            
            await MainActor.run {
                if httpStatus >= 200 && httpStatus < 300 {
                    status = "🎶 Exchange success (\(httpStatus)):\n\(json)"
                } else {
                    status = "❌ Exchange failed (\(httpStatus)):\n\(json)"
                }
            }
        } catch {
            await MainActor.run {
                status = "❌ Backend error: \(error.localizedDescription)"
            }
        }
    }
    
    private func refreshSpotifyToken() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { status = "❌ Not signed into Firebase" }
                return
            }

            let idToken = try await user.getIDToken()

            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyRefresh")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = Data("{}".utf8)

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1
            let json = String(data: data, encoding: .utf8) ?? "nil"

            await MainActor.run {
                if httpStatus >= 200 && httpStatus < 300 {
                    status = "🔄 Refresh success (\(httpStatus)):\n\(json)"
                } else {
                    status = "❌ Refresh failed (\(httpStatus)):\n\(json)"
                }
            }
        } catch {
            await MainActor.run {
                status = "❌ Refresh error: \(error.localizedDescription)"
            }
        }
    }
}
