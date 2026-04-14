//
//  ActivityViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/13/26.
//

import Foundation
import FirebaseAuth

@Observable
final class ActivityViewModel {
    private(set) var unratedTracks: [TrackResult] = []
    var currentTrackId: String? = nil
    var rating: Double = 0
    private(set) var isLoading = true
    private(set) var friendActivity: [FriendActivity] = []

    var isDone: Bool { !isLoading && unratedTracks.isEmpty }

    private let firestoreService = FirestoreService()
    private static let recentlyPlayedURL = URL(
        string: "https://us-east1-onchord-ec86c.cloudfunctions.net/recentlyPlayed"
    )!

    func load(isRefresh: Bool = false) async {
        await MainActor.run { if !isRefresh { isLoading = true } }
        async let tracksLoad: Void = loadUnratedTracks()
        async let activityLoad: Void = loadFriendActivity()
        await tracksLoad
        await activityLoad
    }

    private func loadUnratedTracks() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { isLoading = false }
                return
            }
            let idToken = try await user.getIDToken()

            var request = URLRequest(url: Self.recentlyPlayedURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: [:])

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let trackDicts = json?["tracks"] as? [[String: Any]] ?? []

            let tracks = trackDicts.compactMap { dict -> TrackResult? in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String else { return nil }
                return TrackResult(
                    id: id,
                    name: name,
                    artistName: dict["artistName"] as? String ?? "Unknown Artist",
                    albumName: dict["albumName"] as? String ?? "",
                    albumId: dict["albumId"] as? String,
                    albumType: dict["albumType"] as? String ?? "album",
                    imageUrl: (dict["imageUrl"] as? String).flatMap { URL(string: $0) },
                    largeImageUrl: (dict["largeImageUrl"] as? String).flatMap { URL(string: $0) },
                    albumTrackCount: dict["albumTrackCount"] as? Int ?? 0
                )
            }

            await MainActor.run {
                unratedTracks = tracks
                currentTrackId = tracks.first?.id
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func loadFriendActivity() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let activity = (try? await firestoreService.fetchFriendActivity(userId: uid)) ?? []
        await MainActor.run { friendActivity = activity }
    }

    // Saves the rating for the given track (if one was set) and removes it from
    // the carousel. Called either when the user swipes away or, for the last
    // remaining track, as soon as a star is tapped.
    func saveIfRated(trackId: String) async {
        // Capture rating before any suspension point so a concurrent swipe
        // cannot overwrite it before we finish reading it.
        let capturedRating = rating

        guard capturedRating > 0,
              let index = unratedTracks.firstIndex(where: { $0.id == trackId }),
              let uid = Auth.auth().currentUser?.uid else {
            await MainActor.run { rating = 0 }
            return
        }

        let track = unratedTracks[index]
        let docId = "\(uid)_\(track.id)"
        try? await firestoreService.saveRating(capturedRating, docId: docId, userId: uid, track: track)

        await MainActor.run {
            unratedTracks.remove(at: index)
            rating = 0
            // If this was the last track (or the one still selected), clear selection.
            if currentTrackId == trackId {
                currentTrackId = unratedTracks.first?.id
            }
        }
    }
}
