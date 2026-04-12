//
//  SearchViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class SearchViewModel {
    var query = ""
    var searchMode: SearchMode = .music

    private(set) var items: [SearchItem] = []
    private(set) var userResults: [UserResult] = []
    private(set) var status = ""
    private(set) var hasSearched = false
    private(set) var searchHistory: [String] = []

    var showHistory: Bool {
        searchMode == .music
            && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && items.isEmpty
    }

    private var searchTask: Task<Void, Never>?
    private let firestoreService = FirestoreService()

    private static let historyKey = "searchHistory"
    private static let maxHistory = 20

    // MARK: - Actions

    func onQueryChanged(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask?.cancel()
        if trimmed.isEmpty {
            items = []
            userResults = []
            hasSearched = false
            status = ""
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func onSearchModeChanged() {
        items = []
        userResults = []
        hasSearched = false
        status = ""
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchTask?.cancel()
        searchTask = Task {
            await performSearch()
        }
    }

    func clearQuery() {
        query = ""
        items = []
        userResults = []
        hasSearched = false
        status = ""
    }

    func triggerSearch(for term: String) {
        query = term
        searchTask?.cancel()
        searchTask = Task {
            await performSearch()
        }
    }

    func loadHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
    }

    func clearHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }

    // MARK: - Private

    private func performSearch() async {
        if searchMode == .music {
            await searchSpotify()
        } else {
            await searchUsers()
        }
    }

    private func searchSpotify() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run { status = "" }

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

            let sorted = Self.parseAndRankResults(json: json, query: trimmed)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                items = sorted
                hasSearched = true
                status = ""
                saveToHistory(trimmed)
            }

        } catch {
            await MainActor.run {
                status = "Error: \(error.localizedDescription)"
                hasSearched = true
            }
        }
    }

    private func searchUsers() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run { status = "" }

        do {
            guard let currentUid = Auth.auth().currentUser?.uid else {
                await MainActor.run { status = "Not signed in" }
                return
            }

            let results = try await firestoreService.searchUsers(
                query: trimmed,
                excludingUid: currentUid
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                userResults = results
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

    private func saveToHistory(_ term: String) {
        var history = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
        history.removeAll { $0.lowercased() == term.lowercased() }
        history.insert(term, at: 0)
        if history.count > Self.maxHistory {
            history = Array(history.prefix(Self.maxHistory))
        }
        UserDefaults.standard.set(history, forKey: Self.historyKey)
        searchHistory = history
    }

    // MARK: - Spotify JSON Parsing

    private static func parseAndRankResults(json: [String: Any], query: String) -> [SearchItem] {
        let q = query.lowercased()
        var scored: [(item: SearchItem, score: Int)] = []

        if let artists = json["artists"] as? [String: Any],
           let list = artists["items"] as? [[String: Any]] {
            for (i, artist) in list.enumerated() {
                let name = artist["name"] as? String ?? "Unknown"
                let id = artist["id"] as? String ?? UUID().uuidString
                let imageUrl = firstImageUrl(from: artist)
                let item = SearchItem.artist(id: id, name: name, imageUrl: imageUrl)
                scored.append((item, relevanceScore(name: name, query: q, index: i)))
            }
        }

        if let albums = json["albums"] as? [String: Any],
           let list = albums["items"] as? [[String: Any]] {
            for (i, album) in list.enumerated() {
                let name = album["name"] as? String ?? "Unknown"
                let id = album["id"] as? String ?? UUID().uuidString
                let albumType = album["album_type"] as? String ?? "album"
                let artistName = allArtistNames(from: album)
                let imageUrl = firstImageUrl(from: album)
                let item = SearchItem.album(id: id, name: name, artistName: artistName,
                                            albumType: albumType, imageUrl: imageUrl)
                scored.append((item, relevanceScore(name: name, query: q, index: i)))
            }
        }

        if let tracks = json["tracks"] as? [String: Any],
           let list = tracks["items"] as? [[String: Any]] {
            for (i, track) in list.enumerated() {
                let name = track["name"] as? String ?? "Unknown"
                let id = track["id"] as? String ?? UUID().uuidString
                let artistName = allArtistNames(from: track)
                let albumDict = track["album"] as? [String: Any]
                let albumName = albumDict?["name"] as? String ?? ""
                let albumId = albumDict?["id"] as? String
                let albumType = albumDict?["album_type"] as? String ?? "album"
                let imageUrl = albumDict.flatMap { firstImageUrl(from: $0) }
                let largeImageUrl = albumDict.flatMap { firstImageUrl(from: $0, preferLarge: true) }
                let albumTrackCount = albumDict?["total_tracks"] as? Int ?? 0
                let tr = TrackResult(id: id, name: name, artistName: artistName,
                                     albumName: albumName, albumId: albumId,
                                     albumType: albumType, imageUrl: imageUrl,
                                     largeImageUrl: largeImageUrl,
                                     albumTrackCount: albumTrackCount)
                scored.append((.track(tr), relevanceScore(name: name, query: q, index: i)))
            }
        }

        return scored
            .enumerated()
            .sorted { a, b in
                if a.element.score != b.element.score {
                    return a.element.score > b.element.score
                }
                return a.offset < b.offset
            }
            .map(\.element.item)
    }

    private static func relevanceScore(name: String, query: String, index: Int) -> Int {
        let lower = name.lowercased()
        let positionBonus = max(10 - index, 0)
        if lower == query { return 100 + positionBonus }
        if lower.hasPrefix(query) { return 75 + positionBonus }
        if lower.contains(query) { return 50 + positionBonus }
        return positionBonus
    }

    static func firstImageUrl(from item: [String: Any], preferLarge: Bool = false) -> URL? {
        guard let images = item["images"] as? [[String: Any]],
              let picked = preferLarge ? images.first : images.last,
              let urlString = picked["url"] as? String else {
            return nil
        }
        return URL(string: urlString)
    }

    static func allArtistNames(from item: [String: Any]) -> String {
        guard let artists = item["artists"] as? [[String: Any]], !artists.isEmpty else {
            return "Unknown Artist"
        }
        return artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
    }
}
