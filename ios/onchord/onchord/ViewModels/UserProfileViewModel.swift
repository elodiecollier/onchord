//
//  UserProfileViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class UserProfileViewModel {
    let user: UserResult

    private(set) var isFollowing = false
    private(set) var isLoading = true
    private(set) var isToggling = false
    private(set) var ratedSongs: [RatedSong] = []
    private(set) var ratedAlbums: [RatedAlbum] = []
    private(set) var isLoadingActivity = true

    private let firestoreService = FirestoreService()

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    private var followDocId: String? {
        guard let uid = currentUid else { return nil }
        return "\(uid)_\(user.id)"
    }

    init(user: UserResult) {
        self.user = user
    }

    func load() async {
        await checkFollowStatus()
        await loadUserActivity()
    }

    func toggleFollow() async {
        guard let uid = currentUid, let docId = followDocId else { return }

        await MainActor.run { isToggling = true }

        do {
            if isFollowing {
                try await firestoreService.unfollow(docId: docId)
                await MainActor.run { isFollowing = false }
            } else {
                try await firestoreService.follow(
                    docId: docId,
                    followerId: uid,
                    followingId: user.id
                )
                await MainActor.run { isFollowing = true }
            }
        } catch {
            // Silently fail — button state stays unchanged
        }

        await MainActor.run { isToggling = false }
    }

    private func checkFollowStatus() async {
        guard let docId = followDocId else {
            await MainActor.run { isLoading = false }
            return
        }

        do {
            let following = try await firestoreService.isFollowing(docId: docId)
            await MainActor.run {
                isFollowing = following
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func loadUserActivity() async {
        do {
            let result = try await firestoreService.fetchReviews(userId: user.id)
            await MainActor.run {
                ratedSongs = result.songs
                ratedAlbums = result.albums
                isLoadingActivity = false
            }
        } catch {
            await MainActor.run { isLoadingActivity = false }
        }
    }
}
