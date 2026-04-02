//
//  SearchView.swift
//  onchord
//
//  Created by Elodie Collier on 4/2/26.
//

import SwiftUI
import FirebaseAuth

struct SearchView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var query = ""
    @State private var results: [String] = []
    @State private var status = ""

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Log out") {
                    authManager.logout()
                }
                .foregroundColor(.red)
                .padding(.trailing)
            }

            TextField("Search music...", text: $query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Search") {
                Task { await searchSpotify() }
            }

            Text(status)
                .padding()

            List(results, id: \.self) { item in
                Text(item)
            }
        }
    }

    private func searchSpotify() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { status = "❌ Not signed in" }
                return
            }

            let idToken = try await user.getIDToken()

            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifySearch")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "q": query,
                "type": "album,track",
                "limit": 10
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            var newResults: [String] = []

            if let albums = json?["albums"] as? [String: Any],
               let items = albums["items"] as? [[String: Any]] {
                for album in items {
                    let name = album["name"] as? String ?? "Unknown"
                    newResults.append("💿 \(name)")
                }
            }

            if let tracks = json?["tracks"] as? [String: Any],
               let items = tracks["items"] as? [[String: Any]] {
                for track in items {
                    let name = track["name"] as? String ?? "Unknown"
                    newResults.append("🎵 \(name)")
                }
            }

            await MainActor.run {
                results = newResults
                status = "✅ Results loaded"
            }

        } catch {
            await MainActor.run {
                status = "❌ Error: \(error.localizedDescription)"
            }
        }
    }
}
