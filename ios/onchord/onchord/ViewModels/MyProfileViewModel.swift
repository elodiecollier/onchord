//
//  MyProfileViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class MyProfileViewModel {
    private(set) var ratedSongs: [RatedSong] = []
    private(set) var ratedAlbums: [RatedAlbum] = []
    private(set) var isLoading = true
    private(set) var followerCount: Int = 0
    private(set) var followingCount: Int = 0

    var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    private let firestoreService = FirestoreService()

    func load() async {
        await loadReviews()
        await loadFollowCounts()
    }

    private func loadReviews() async {
        guard let uid = currentUid else {
            await MainActor.run { isLoading = false }
            return
        }

        do {
            let result = try await firestoreService.fetchReviews(userId: uid)
            await MainActor.run {
                ratedSongs = result.songs
                ratedAlbums = result.albums
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func loadFollowCounts() async {
        guard let uid = currentUid else { return }

        do {
            let counts = try await firestoreService.fetchFollowCounts(userId: uid)
            await MainActor.run {
                followerCount = counts.followers
                followingCount = counts.following
            }
        } catch {
            // Silently fail — counts stay at 0
        }
    }
}
