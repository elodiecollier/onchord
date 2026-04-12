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
    private(set) var friendCount: Int = 0

    var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    private let firestoreService = FirestoreService()

    func load() async {
        await loadReviews()
        await loadFriendCount()
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

    private func loadFriendCount() async {
        guard let uid = currentUid else { return }
        do {
            let count = try await firestoreService.fetchFriendCount(userId: uid)
            await MainActor.run { friendCount = count }
        } catch {}
    }
}
