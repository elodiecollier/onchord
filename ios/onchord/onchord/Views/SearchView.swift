//
//  SearchView.swift
//  onchord
//
//  Created by Elodie Collier on 4/2/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TrackResult: Identifiable, Hashable {
    let id: String
    let name: String
    let artistName: String
    let albumName: String
    let imageUrl: URL?
}

struct AlbumResult: Identifiable, Hashable {
    let id: String
    let name: String
    let artistName: String
    let albumType: String
    let imageUrl: URL?
}

struct ArtistResult: Identifiable, Hashable {
    let id: String
    let name: String
    let imageUrl: URL?
}

enum SearchItem: Identifiable {
    case artist(id: String, name: String, imageUrl: URL?)
    case album(id: String, name: String, artistName: String, albumType: String, imageUrl: URL?)
    case track(TrackResult)

    var id: String {
        switch self {
        case .artist(let id, _, _): return "artist-\(id)"
        case .album(let id, _, _, _, _): return "album-\(id)"
        case .track(let t): return "track-\(t.id)"
        }
    }

    var name: String {
        switch self {
        case .artist(_, let name, _): return name
        case .album(_, let name, _, _, _): return name
        case .track(let t): return t.name
        }
    }
}

struct UserResult: Identifiable, Hashable {
    let id: String
    let displayName: String
    let profileImageUrl: URL?
}

enum SearchMode: String, CaseIterable {
    case music = "Music"
    case people = "People"
}

struct SearchView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var query = ""
    @State private var items: [SearchItem] = []
    @State private var userResults: [UserResult] = []
    @State private var status = ""
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?
    @State private var searchHistory: [String] = []
    @State private var searchMode: SearchMode = .music

    private static let historyKey = "searchHistory"
    private static let maxHistory = 20

    private var showHistory: Bool {
        searchMode == .music && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && items.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(searchMode == .music ? "Search music..." : "Search people...", text: $query)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button {
                        query = ""
                        items = []
                        userResults = []
                        hasSearched = false
                        status = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Picker("Search Mode", selection: $searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if !status.isEmpty {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            if showHistory && !searchHistory.isEmpty {
                List {
                    Section {
                        ForEach(searchHistory, id: \.self) { term in
                            Button {
                                query = term
                                triggerSearch(for: term)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.secondary)
                                    Text(term)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear") {
                                searchHistory = []
                                UserDefaults.standard.removeObject(forKey: Self.historyKey)
                            }
                            .font(.caption)
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
            } else if searchMode == .people {
                if hasSearched && userResults.isEmpty {
                    Spacer()
                    Text("No people found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if !userResults.isEmpty {
                    List(userResults) { user in
                        NavigationLink(value: user) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: user.profileImageUrl, isCircle: true)
                                Text(user.displayName)
                                    .font(.body)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: UserResult.self) { user in
                        UserProfileView(user: user)
                    }
                } else {
                    Spacer()
                }
            } else if hasSearched && items.isEmpty {
                Spacer()
                Text("No results found")
                    .foregroundColor(.secondary)
                Spacer()
            } else if !items.isEmpty {
                List(items) { item in
                    switch item {
                    case .artist(let id, let name, let imageUrl):
                        NavigationLink(value: ArtistResult(id: id, name: name, imageUrl: imageUrl)) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: imageUrl, isCircle: true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text("Artist")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                    case .album(let id, let name, let artistName, let albumType, let imageUrl):
                        NavigationLink(value: AlbumResult(id: id, name: name, artistName: artistName, albumType: albumType, imageUrl: imageUrl)) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: imageUrl, isCircle: false)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.body)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        Text(artistName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        if albumType != "album" {
                                            Text("·")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(albumType == "single" ? "EP / Single" : "Compilation")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                        }

                    case .track(let track):
                        NavigationLink(value: track) {
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
                .listStyle(.plain)
                .navigationDestination(for: TrackResult.self) { track in
                    SongDetailView(track: track)
                }
                .navigationDestination(for: AlbumResult.self) { album in
                    AlbumDetailView(album: album)
                }
                .navigationDestination(for: ArtistResult.self) { artist in
                    ArtistDetailView(artist: artist)
                }
            } else {
                Spacer()
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadHistory() }
        .onChange(of: query) { _, newValue in
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
                if searchMode == .music {
                    await searchSpotify()
                } else {
                    await searchUsers()
                }
            }
        }
        .onChange(of: searchMode) { _, _ in
            items = []
            userResults = []
            hasSearched = false
            status = ""
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            searchTask?.cancel()
            searchTask = Task {
                if searchMode == .music {
                    await searchSpotify()
                } else {
                    await searchUsers()
                }
            }
        }
    }

    private func triggerSearch(for term: String) {
        searchTask?.cancel()
        searchTask = Task {
            if searchMode == .music {
                await searchSpotify()
            } else {
                await searchUsers()
            }
        }
    }

    private func searchSpotify() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            status = ""
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

            // Collect all results with a relevance score
            let q = trimmed.lowercased()
            var scored: [(item: SearchItem, score: Int)] = []

            if let artists = json["artists"] as? [String: Any],
               let list = artists["items"] as? [[String: Any]] {
                for (i, artist) in list.enumerated() {
                    let name = artist["name"] as? String ?? "Unknown"
                    let id = artist["id"] as? String ?? UUID().uuidString
                    let imageUrl = Self.firstImageUrl(from: artist)
                    let item = SearchItem.artist(id: id, name: name, imageUrl: imageUrl)
                    scored.append((item, Self.relevanceScore(name: name, query: q, index: i)))
                }
            }

            if let albums = json["albums"] as? [String: Any],
               let list = albums["items"] as? [[String: Any]] {
                for (i, album) in list.enumerated() {
                    let name = album["name"] as? String ?? "Unknown"
                    let id = album["id"] as? String ?? UUID().uuidString
                    let albumType = album["album_type"] as? String ?? "album"
                    let artistName = Self.allArtistNames(from: album)
                    let imageUrl = Self.firstImageUrl(from: album)
                    let item = SearchItem.album(id: id, name: name, artistName: artistName,
                                                albumType: albumType, imageUrl: imageUrl)
                    scored.append((item, Self.relevanceScore(name: name, query: q, index: i)))
                }
            }

            if let tracks = json["tracks"] as? [String: Any],
               let list = tracks["items"] as? [[String: Any]] {
                for (i, track) in list.enumerated() {
                    let name = track["name"] as? String ?? "Unknown"
                    let id = track["id"] as? String ?? UUID().uuidString
                    let artistName = Self.allArtistNames(from: track)
                    let albumDict = track["album"] as? [String: Any]
                    let albumName = albumDict?["name"] as? String ?? ""
                    let imageUrl = albumDict.flatMap { Self.firstImageUrl(from: $0) }
                    let tr = TrackResult(id: id, name: name, artistName: artistName,
                                         albumName: albumName, imageUrl: imageUrl)
                    scored.append((.track(tr), Self.relevanceScore(name: name, query: q, index: i)))
                }
            }

            // Sort by score descending, then by original order within same score
            let sorted = scored
                .enumerated()
                .sorted { a, b in
                    if a.element.score != b.element.score {
                        return a.element.score > b.element.score
                    }
                    return a.offset < b.offset
                }
                .map(\.element.item)

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

            let db = Firestore.firestore()
            let lowered = trimmed.lowercased()
            let snapshot = try await db.collection("users")
                .whereField("displayNameLower", isGreaterThanOrEqualTo: lowered)
                .whereField("displayNameLower", isLessThan: lowered + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()

            guard !Task.isCancelled else { return }

            let results: [UserResult] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let uid = doc.documentID
                guard uid != currentUid else { return nil }
                let displayName = data["displayName"] as? String ?? "Unknown"
                let profileImageUrl = (data["profileImageUrl"] as? String).flatMap { URL(string: $0) }
                return UserResult(id: uid, displayName: displayName, profileImageUrl: profileImageUrl)
            }

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

    /// Score an item's name against the query. Higher = better match.
    /// Index is the Spotify-returned position (lower = Spotify thinks more relevant).
    private static func relevanceScore(name: String, query: String, index: Int) -> Int {
        let lower = name.lowercased()
        let positionBonus = max(10 - index, 0) // Spotify's own ranking, 10..0
        if lower == query { return 100 + positionBonus }
        if lower.hasPrefix(query) { return 75 + positionBonus }
        if lower.contains(query) { return 50 + positionBonus }
        return positionBonus
    }

    private static func firstImageUrl(from item: [String: Any], preferLarge: Bool = false) -> URL? {
        guard let images = item["images"] as? [[String: Any]],
              let picked = preferLarge ? images.first : images.last,
              let urlString = picked["url"] as? String else {
            return nil
        }
        return URL(string: urlString)
    }

    private static func allArtistNames(from item: [String: Any]) -> String {
        guard let artists = item["artists"] as? [[String: Any]], !artists.isEmpty else {
            return "Unknown Artist"
        }
        return artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
    }

    private func loadHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
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

// MARK: - Song Detail View

struct SongDetailView: View {
    let track: TrackResult
    @State private var rating: Double = 0
    @State private var isSaving = false
    @State private var existingDocId: String?

    private var reviewDocId: String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return "\(uid)_\(track.id)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Album art
                AsyncImage(url: track.imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(maxWidth: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)

                // Song info
                VStack(spacing: 6) {
                    Text(track.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(track.artistName)
                        .font(.body)
                        .foregroundColor(.secondary)

                    if !track.albumName.isEmpty {
                        Text(track.albumName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Rating
                VStack(spacing: 8) {
                    Text("Your Rating")
                        .font(.headline)

                    StarRatingView(rating: $rating)

                    if rating > 0 {
                        Text(formattedRating)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if isSaving {
                    ProgressView()
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Rate Song")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadRating() }
        .onChange(of: rating) { _, newValue in
            Task { await saveRating(newValue) }
        }
    }

    private var formattedRating: String {
        if rating == rating.rounded() {
            return "\(Int(rating)) / 5"
        }
        return String(format: "%.1f / 5", rating)
    }

    private func loadRating() async {
        guard let docId = reviewDocId else { return }
        do {
            let doc = try await Firestore.firestore()
                .collection("reviews").document(docId).getDocument()
            if let data = doc.data(), let saved = data["rating"] as? Double {
                await MainActor.run { rating = saved }
            }
        } catch {
            // No existing rating — that's fine
        }
    }

    private func saveRating(_ value: Double) async {
        guard let uid = Auth.auth().currentUser?.uid,
              let docId = reviewDocId else { return }

        await MainActor.run { isSaving = true }

        let data: [String: Any] = [
            "userId": uid,
            "trackId": track.id,
            "trackName": track.name,
            "artistName": track.artistName,
            "albumName": track.albumName,
            "albumImageUrl": track.imageUrl?.absoluteString ?? "",
            "rating": value,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await Firestore.firestore()
                .collection("reviews").document(docId)
                .setData(data, merge: true)
        } catch {
            // Silently fail for now — rating is still shown locally
        }

        await MainActor.run { isSaving = false }
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImage(for: star))
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        let full = Double(star)
                        let half = full - 0.5
                        if rating == full {
                            rating = half       // filled → half
                        } else if rating == half {
                            rating = 0           // half → clear
                        } else {
                            rating = full        // anything else → filled
                        }
                    }
            }
        }
    }

    private func starImage(for position: Int) -> String {
        if rating >= Double(position) {
            return "star.fill"
        } else if rating >= Double(position) - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Album Detail View

struct AlbumDetailView: View {
    let album: AlbumResult
    @State private var tracks: [TrackResult] = []
    @State private var ratings: [String: Double] = [:]  // trackId -> rating
    @State private var largeImageUrl: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var averageRating: Double? {
        guard !tracks.isEmpty else { return nil }
        let rated = tracks.compactMap { ratings[$0.id] }
        guard rated.count == tracks.count else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album artwork
                AsyncImage(url: largeImageUrl ?? album.imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(maxWidth: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)

                // Album info
                VStack(spacing: 6) {
                    Text(album.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(album.artistName)
                        .font(.body)
                        .foregroundColor(.secondary)

                    if album.albumType != "album" {
                        Text(album.albumType == "single" ? "EP / Single" : "Compilation")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)

                // Average rating
                if let avg = averageRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", avg))
                            .font(.headline)
                        Text("average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 20)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                } else {
                    // Track list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink(value: track) {
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, alignment: .trailing)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.body)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                        if track.artistName != album.artistName {
                                            Text(track.artistName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    if let r = ratings[track.id] {
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                            Text(r == r.rounded() ? "\(Int(r))" : String(format: "%.1f", r))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }

                            if index < tracks.count - 1 {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Album")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAlbumTracks() }
        .onAppear { Task { await loadRatings() } }
    }

    private func loadAlbumTracks() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { errorMessage = "Not signed in"; isLoading = false }
                return
            }

            let idToken = try await user.getIDToken()

            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyAlbumTracks")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["albumId": album.id])

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200...299).contains(httpStatus) else {
                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                let msg = errorBody?["error"] as? String ?? "Error \(httpStatus)"
                await MainActor.run { errorMessage = msg; isLoading = false }
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                await MainActor.run { errorMessage = "Unexpected response"; isLoading = false }
                return
            }

            // Get large album image
            let images = json["images"] as? [[String: Any]] ?? []
            let largeUrl = images.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }

            // Parse tracks
            let tracksObj = json["tracks"] as? [String: Any]
            let trackItems = tracksObj?["items"] as? [[String: Any]] ?? []
            let albumImageUrl = largeUrl ?? album.imageUrl

            let parsed: [TrackResult] = trackItems.compactMap { item in
                guard let id = item["id"] as? String,
                      let name = item["name"] as? String else { return nil }
                let artists = item["artists"] as? [[String: Any]] ?? []
                let artistName = artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
                return TrackResult(
                    id: id, name: name, artistName: artistName.isEmpty ? "Unknown Artist" : artistName,
                    albumName: album.name, imageUrl: albumImageUrl
                )
            }

            await MainActor.run {
                largeImageUrl = largeUrl
                tracks = parsed
                isLoading = false
            }

            await loadRatings()

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadRatings() async {
        guard let uid = Auth.auth().currentUser?.uid, !tracks.isEmpty else { return }

        var newRatings: [String: Double] = [:]
        for track in tracks {
            let docId = "\(uid)_\(track.id)"
            do {
                let doc = try await Firestore.firestore()
                    .collection("reviews").document(docId).getDocument()
                if let data = doc.data(), let rating = data["rating"] as? Double {
                    newRatings[track.id] = rating
                }
            } catch {
                // Skip — no rating for this track
            }
        }

        await MainActor.run { ratings = newRatings }
    }
}

// MARK: - Artist Detail View

struct ArtistDetailView: View {
    let artist: ArtistResult
    @State private var largeImageUrl: URL?
    @State private var albums: [AlbumResult] = []
    @State private var singles: [AlbumResult] = []
    @State private var releaseYears: [String: String] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Artist image
                AsyncImage(url: largeImageUrl ?? artist.imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(radius: 8)

                Text(artist.name)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding(.top, 20)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                } else {
                    // Albums section
                    if !albums.isEmpty {
                        discographySection(title: "Albums", items: albums)
                    }

                    // Singles & EPs section
                    if !singles.isEmpty {
                        discographySection(title: "Singles & EPs", items: singles)
                    }

                    if albums.isEmpty && singles.isEmpty {
                        Text("No releases found")
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Artist")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadArtistAlbums() }
    }

    @ViewBuilder
    private func discographySection(title: String, items: [AlbumResult]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, album in
                    NavigationLink(value: album) {
                        HStack(spacing: 12) {
                            AsyncImage(url: album.imageUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                default:
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay {
                                            Image(systemName: "music.note")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.name)
                                    .font(.body)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                HStack(spacing: 4) {
                                    if let year = releaseYears[album.id] {
                                        Text(year)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if album.albumType != "album" {
                                        Text("·")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(album.albumType == "single" ? "Single" : "Compilation")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    if index < items.count - 1 {
                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
    }

    private func loadArtistAlbums() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { errorMessage = "Not signed in"; isLoading = false }
                return
            }

            let idToken = try await user.getIDToken()

            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyArtistAlbums")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["artistId": artist.id])

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200...299).contains(httpStatus) else {
                let rawBody = String(data: data, encoding: .utf8) ?? "(non-utf8)"
                print("[ArtistDetail] HTTP \(httpStatus) full response: \(rawBody)")
                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                // Check for nested Spotify error format: {"spotifyError":{"error":{"message":"..."}}}
                let msg: String
                if let spotifyErr = errorBody?["spotifyError"] as? [String: Any],
                   let errObj = spotifyErr["error"] as? [String: Any],
                   let message = errObj["message"] as? String {
                    let source = errorBody?["source"] as? String ?? "unknown"
                    msg = "\(source): \(message)"
                } else {
                    msg = errorBody?["error"] as? String ?? "Error \(httpStatus)"
                }
                await MainActor.run { errorMessage = msg; isLoading = false }
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                await MainActor.run { errorMessage = "Unexpected response"; isLoading = false }
                return
            }

            // Parse artist profile for large image
            let artistObj = json["artist"] as? [String: Any]
            let images = artistObj?["images"] as? [[String: Any]] ?? []
            let largeUrl = images.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }

            // Parse albums
            let albumsObj = json["albums"] as? [String: Any]
            let albumItems = albumsObj?["items"] as? [[String: Any]] ?? []

            var albumsWithDate: [(AlbumResult, String)] = []
            var singlesWithDate: [(AlbumResult, String)] = []

            for item in albumItems {
                guard let id = item["id"] as? String,
                      let name = item["name"] as? String else { continue }
                let albumType = item["album_type"] as? String ?? "album"
                let artists = item["artists"] as? [[String: Any]] ?? []
                let artistName = artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
                let itemImages = item["images"] as? [[String: Any]] ?? []
                let imageUrl = itemImages.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }
                let releaseDate = item["release_date"] as? String ?? ""

                let album = AlbumResult(
                    id: id, name: name,
                    artistName: artistName.isEmpty ? "Unknown Artist" : artistName,
                    albumType: albumType, imageUrl: imageUrl
                )

                if albumType == "album" {
                    albumsWithDate.append((album, releaseDate))
                } else {
                    singlesWithDate.append((album, releaseDate))
                }
            }

            // Sort by release_date descending (newest first)
            albumsWithDate.sort { $0.1 > $1.1 }
            singlesWithDate.sort { $0.1 > $1.1 }

            // Build release year lookup
            var years: [String: String] = [:]
            for (album, date) in albumsWithDate + singlesWithDate {
                let year = String(date.prefix(4))
                if year.count == 4 { years[album.id] = year }
            }

            await MainActor.run {
                self.largeImageUrl = largeUrl
                self.albums = albumsWithDate.map(\.0)
                self.singles = singlesWithDate.map(\.0)
                self.releaseYears = years
                isLoading = false
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
