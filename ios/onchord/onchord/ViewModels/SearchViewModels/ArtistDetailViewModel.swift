//
//  ArtistDetailViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class ArtistDetailViewModel {
    let artist: ArtistResult

    private(set) var largeImageUrl: URL?
    private(set) var albums: [AlbumResult] = []
    private(set) var singles: [AlbumResult] = []
    private(set) var releaseYears: [String: String] = [:]
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    // All-albums pagination (used by AllAlbumsForArtistView)
    private(set) var allAlbums: [AlbumResult] = []
    private(set) var allSingles: [AlbumResult] = []
    private(set) var allReleaseYears: [String: String] = [:]
    private(set) var isLoadingAllAlbums = false
    private(set) var allAlbumsLoaded = false

    private(set) var songsRatedCount: Int = 0
    private(set) var totalSongsEstimate: Int = 0
    private(set) var albumsRatedCount: Int = 0
    private(set) var totalAlbumsCountFromAPI: Int = 0
    private(set) var averageArtistRating: Double? = nil

    var songsRatedPercent: String {
        guard totalSongsEstimate > 0 else { return "—" }
        let pct = Double(songsRatedCount) / Double(totalSongsEstimate) * 100
        return "\(Int(pct.rounded()))%"
    }

    var albumsRatedDisplay: String {
        "\(albumsRatedCount)/\(totalAlbumsCountFromAPI)"
    }

    init(artist: ArtistResult) {
        self.artist = artist
    }

    func load() async {
        await loadArtistAlbums()
        await loadArtistStats()
    }

    func refreshStats() async {
        await loadArtistStats()
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
                if httpStatus == 429 {
                    await MainActor.run {
                        errorMessage = "Spotify is temporarily unavailable — please try again in a few minutes"
                        isLoading = false
                    }
                    return
                }
                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
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

            let artistObj = json["artist"] as? [String: Any]
            let images = artistObj?["images"] as? [[String: Any]] ?? []
            let largeUrl = images.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }

            let albumsObj = json["albums"] as? [String: Any]
            let albumItems = albumsObj?["items"] as? [[String: Any]] ?? []
            let apiAlbumTotal = albumsObj?["total"] as? Int ?? 0

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

            albumsWithDate.sort { $0.1 > $1.1 }
            singlesWithDate.sort { $0.1 > $1.1 }

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
                self.totalAlbumsCountFromAPI = apiAlbumTotal > 0 ? apiAlbumTotal : albumsWithDate.count
                isLoading = false
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadArtistStats() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("reviews")
            .whereField("userId", isEqualTo: uid)
            .whereField("artistName", isEqualTo: artist.name)
            .getDocuments() else { return }

        var albumGroups: [String: (ratedCount: Int, totalCount: Int)] = [:]
        var totalRating: Double = 0
        var validRatingCount = 0

        for doc in snapshot.documents {
            let data = doc.data()
            guard let rating = data["rating"] as? Double else { continue }
            totalRating += rating
            validRatingCount += 1

            let albumName = data["albumName"] as? String ?? ""
            let trackCount = data["albumTrackCount"] as? Int ?? 0
            if !albumName.isEmpty && trackCount > 0 {
                if var group = albumGroups[albumName] {
                    group.ratedCount += 1
                    albumGroups[albumName] = group
                } else {
                    albumGroups[albumName] = (ratedCount: 1, totalCount: trackCount)
                }
            }
        }

        let totalSongs = albumGroups.values.reduce(0) { $0 + $1.totalCount }
        let ratedSongs = albumGroups.values.reduce(0) { $0 + $1.ratedCount }
        let albumsRated = albumGroups.values.filter { $0.ratedCount > 0 }.count
        let avg = validRatingCount > 0 ? totalRating / Double(validRatingCount) : nil

        await MainActor.run {
            songsRatedCount = ratedSongs
            totalSongsEstimate = totalSongs
            albumsRatedCount = albumsRated
            averageArtistRating = avg
        }
    }

    func loadAllAlbums() async {
        guard !isLoadingAllAlbums, !allAlbumsLoaded else { return }
        await MainActor.run { isLoadingAllAlbums = true }

        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { isLoadingAllAlbums = false }
                return
            }
            let idToken = try await user.getIDToken()

            var allAlbumsWithDate: [(AlbumResult, String)] = []
            var allSinglesWithDate: [(AlbumResult, String)] = []
            var allYears: [String: String] = [:]
            var seenIds: Set<String> = []
            var offset = 0
            var hasNextPage = true

            while hasNextPage {
                let body: [String: Any] = ["artistId": artist.id, "offset": offset]
                var request = URLRequest(
                    url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyArtistAlbums")!
                )
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard (200...299).contains((response as? HTTPURLResponse)?.statusCode ?? 0),
                      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { break }

                let albumsObj = json["albums"] as? [String: Any]
                let items = albumsObj?["items"] as? [[String: Any]] ?? []

                // Use Spotify's "next" cursor — if null/missing there are no more pages
                let nextValue = albumsObj?["next"]
                hasNextPage = nextValue != nil && !(nextValue is NSNull)

                if items.isEmpty { break }

                var newItemCount = 0
                for item in items {
                    guard let id = item["id"] as? String,
                          let name = item["name"] as? String,
                          !seenIds.contains(id) else { continue }
                    seenIds.insert(id)
                    newItemCount += 1

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
                    let year = String(releaseDate.prefix(4))
                    if year.count == 4 { allYears[id] = year }

                    if albumType == "album" {
                        allAlbumsWithDate.append((album, releaseDate))
                    } else {
                        allSinglesWithDate.append((album, releaseDate))
                    }
                }

                // If backend ignores offset and returns the same items, stop to avoid an infinite loop
                if newItemCount == 0 { break }

                offset += items.count

                // Small delay between pages to avoid Spotify rate limiting
                if hasNextPage {
                    try await Task.sleep(nanoseconds: 250_000_000)
                }
            }

            allAlbumsWithDate.sort { $0.1 > $1.1 }
            allSinglesWithDate.sort { $0.1 > $1.1 }

            await MainActor.run {
                allAlbums = allAlbumsWithDate.map(\.0)
                allSingles = allSinglesWithDate.map(\.0)
                allReleaseYears = allYears
                isLoadingAllAlbums = false
                allAlbumsLoaded = true
            }

        } catch {
            await MainActor.run { isLoadingAllAlbums = false }
        }
    }
}
