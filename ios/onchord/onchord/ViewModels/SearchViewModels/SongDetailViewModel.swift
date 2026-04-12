//
//  SongDetailViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class SongDetailViewModel {
    let track: TrackResult

    var rating: Double = 0
    private(set) var isSaving = false
    private(set) var friendRatings: [FriendTrackRating] = []

    var formattedRating: String {
        if rating == rating.rounded() {
            return "\(Int(rating)) / 5"
        }
        return String(format: "%.1f / 5", rating)
    }

    private let firestoreService = FirestoreService()

    private var reviewDocId: String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return "\(uid)_\(track.id)"
    }

    init(track: TrackResult) {
        self.track = track
    }

    func loadRating() async {
        guard let uid = Auth.auth().currentUser?.uid,
              let docId = reviewDocId else { return }
        async let savedRating = firestoreService.loadRating(docId: docId)
        async let friendRatingsResult = firestoreService.fetchFriendRatingsForTrack(trackId: track.id, currentUserId: uid)
        let (rating, friends) = await (try? savedRating, try? friendRatingsResult)
        await MainActor.run {
            if let rating { self.rating = rating }
            self.friendRatings = friends ?? []
        }
    }

    func saveRating(_ value: Double) async {
        guard let uid = Auth.auth().currentUser?.uid,
              let docId = reviewDocId else { return }

        await MainActor.run { isSaving = true }

        try? await firestoreService.saveRating(
            value,
            docId: docId,
            userId: uid,
            track: track
        )

        await MainActor.run { isSaving = false }
    }
}
