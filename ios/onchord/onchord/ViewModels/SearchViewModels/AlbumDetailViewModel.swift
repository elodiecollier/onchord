//
//  AlbumDetailViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class AlbumDetailViewModel {
    let album: AlbumResult

    private(set) var tracks: [TrackResult] = []
    private(set) var ratings: [String: Double] = [:]
    private(set) var largeImageUrl: URL?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    var averageRating: Double? {
        guard !tracks.isEmpty else { return nil }
        let rated = tracks.compactMap { ratings[$0.id] }
        guard rated.count == tracks.count else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    private let firestoreService = FirestoreService()

    init(album: AlbumResult) {
        self.album = album
    }

    func load() async {
        await loadAlbumTracks()
    }

    func refreshRatings() async {
        await loadRatings()
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

            let images = json["images"] as? [[String: Any]] ?? []
            let largeUrl = images.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }

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
        let newRatings = await firestoreService.loadRatings(for: tracks, userId: uid)
        await MainActor.run { ratings = newRatings }
    }
}
