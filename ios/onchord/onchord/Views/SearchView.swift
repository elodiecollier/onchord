//
//  SearchView.swift
//  onchord
//
//  Created by Elodie Collier on 4/2/26.
//

import SwiftUI
import FirebaseAuth

struct ArtistResult: Identifiable {
    let id: String
    let name: String
    let imageUrl: URL?
}

struct AlbumResult: Identifiable {
    let id: String
    let name: String
    let artistName: String
    let albumType: String // "album", "single", "compilation"
    let imageUrl: URL?

    var typeLabel: String? {
        switch albumType {
        case "single": return "EP / Single"
        case "compilation": return "Compilation"
        default: return nil
        }
    }
}

struct TrackResult: Identifiable {
    let id: String
    let name: String
    let artistName: String
    let imageUrl: URL?
}

struct SearchResults {
    var artists: [ArtistResult] = []
    var albums: [AlbumResult] = []
    var tracks: [TrackResult] = []

    var isEmpty: Bool { artists.isEmpty && albums.isEmpty && tracks.isEmpty }
}

struct SearchView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var query = ""
    @State private var results = SearchResults()
    @State private var status = ""
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Log out") {
                    authManager.logout()
                }
                .foregroundColor(.red)
                .padding(.trailing)
            }

            HStack {
                TextField("Search music...", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        Task { await searchSpotify() }
                    }

                Button("Search") {
                    Task { await searchSpotify() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            if !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            if hasSearched && results.isEmpty {
                Spacer()
                Text("No results found")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    if !results.artists.isEmpty {
                        Section("Artists") {
                            ForEach(results.artists) { artist in
                                HStack(spacing: 12) {
                                    SearchArtworkView(url: artist.imageUrl, isCircle: true)
                                    Text(artist.name)
                                        .font(.body)
                                }
                            }
                        }
                    }

                    if !results.albums.isEmpty {
                        Section("Albums & EPs") {
                            ForEach(results.albums) { album in
                                HStack(spacing: 12) {
                                    SearchArtworkView(url: album.imageUrl, isCircle: false)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(album.name)
                                            .font(.body)
                                            .lineLimit(1)
                                        HStack(spacing: 4) {
                                            Text(album.artistName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            if let label = album.typeLabel {
                                                Text("·")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(label)
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !results.tracks.isEmpty {
                        Section("Songs") {
                            ForEach(results.tracks) { track in
                                HStack(spacing: 12) {
                                    SearchArtworkView(url: track.imageUrl, isCircle: false)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.body)
                                            .lineLimit(1)
                                        Text(track.artistName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func searchSpotify() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            status = "Searching..."
            results = SearchResults()
            hasSearched = false
        }

        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { status = "Not signed in" }
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
                "q": trimmed,
                "type": "artist,album,track",
                "limit": 10
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200...299).contains(httpStatus) else {
                // Try to extract error message from response body
                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                let serverMessage = errorBody?["error"] as? String
                    ?? errorBody?["message"] as? String
                    ?? String(data: data, encoding: .utf8)
                    ?? "Unknown error"
                await MainActor.run {
                    status = "Error \(httpStatus): \(serverMessage)"
                    hasSearched = true
                }
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                await MainActor.run {
                    status = "Error: unexpected response format"
                    hasSearched = true
                }
                return
            }

            var newResults = SearchResults()

            // Parse artists
            if let artists = json["artists"] as? [String: Any],
               let items = artists["items"] as? [[String: Any]] {
                for artist in items {
                    let name = artist["name"] as? String ?? "Unknown"
                    let id = artist["id"] as? String ?? UUID().uuidString
                    let imageUrl = Self.firstImageUrl(from: artist)
                    newResults.artists.append(ArtistResult(id: id, name: name, imageUrl: imageUrl))
                }
            }

            // Parse albums
            if let albums = json["albums"] as? [String: Any],
               let items = albums["items"] as? [[String: Any]] {
                for album in items {
                    let name = album["name"] as? String ?? "Unknown"
                    let id = album["id"] as? String ?? UUID().uuidString
                    let albumType = album["album_type"] as? String ?? "album"
                    let artistName = Self.firstArtistName(from: album)
                    let imageUrl = Self.firstImageUrl(from: album)
                    newResults.albums.append(AlbumResult(
                        id: id, name: name, artistName: artistName,
                        albumType: albumType, imageUrl: imageUrl
                    ))
                }
            }

            // Parse tracks
            if let tracks = json["tracks"] as? [String: Any],
               let items = tracks["items"] as? [[String: Any]] {
                for track in items {
                    let name = track["name"] as? String ?? "Unknown"
                    let id = track["id"] as? String ?? UUID().uuidString
                    let artistName = Self.firstArtistName(from: track)
                    // Track images come from the album object
                    let albumDict = track["album"] as? [String: Any]
                    let imageUrl = albumDict.flatMap { Self.firstImageUrl(from: $0) }
                    newResults.tracks.append(TrackResult(
                        id: id, name: name, artistName: artistName, imageUrl: imageUrl
                    ))
                }
            }

            await MainActor.run {
                results = newResults
                hasSearched = true
                status = ""
            }

        } catch {
            await MainActor.run {
                status = "Error: \(error.localizedDescription)"
                hasSearched = true
            }
        }
    }

    private static func firstImageUrl(from item: [String: Any]) -> URL? {
        guard let images = item["images"] as? [[String: Any]],
              let first = images.last, // last = smallest image, good for thumbnails
              let urlString = first["url"] as? String else {
            return nil
        }
        return URL(string: urlString)
    }

    private static func firstArtistName(from item: [String: Any]) -> String {
        guard let artists = item["artists"] as? [[String: Any]],
              let first = artists.first,
              let name = first["name"] as? String else {
            return "Unknown Artist"
        }
        return name
    }
}

struct SearchArtworkView: View {
    let url: URL?
    let isCircle: Bool

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: isCircle ? "person.fill" : "music.note")
                            .foregroundColor(.gray)
                    }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 6)))
    }
}
