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

    private(set) var friendshipStatus: FriendshipStatus = .notFriends
    private(set) var friendCount: Int = 0
    private(set) var isLoading = true
    private(set) var isToggling = false
    private(set) var ratedSongs: [RatedSong] = []
    private(set) var ratedAlbums: [RatedAlbum] = []
    private(set) var isLoadingActivity = true

    private let firestoreService = FirestoreService()

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    init(user: UserResult) {
        self.user = user
    }

    func load() async {
        await checkFriendshipStatus()
        await loadFriendCount()
        await loadUserActivity()
    }

    func sendFriendRequest() async {
        guard let uid = currentUid else { return }
        await MainActor.run { isToggling = true }
        do {
            try await firestoreService.sendFriendRequest(fromId: uid, toId: user.id)
            await MainActor.run { friendshipStatus = .requestSent }
        } catch {}
        await MainActor.run { isToggling = false }
    }

    func cancelFriendRequest() async {
        guard let uid = currentUid else { return }
        await MainActor.run { isToggling = true }
        do {
            try await firestoreService.cancelFriendRequest(fromId: uid, toId: user.id)
            await MainActor.run { friendshipStatus = .notFriends }
        } catch {}
        await MainActor.run { isToggling = false }
    }

    func acceptFriendRequest() async {
        guard let uid = currentUid else { return }
        await MainActor.run { isToggling = true }
        do {
            try await firestoreService.acceptFriendRequest(fromId: user.id, toId: uid)
            await MainActor.run {
                friendshipStatus = .friends
                friendCount += 1
            }
        } catch {}
        await MainActor.run { isToggling = false }
    }

    func denyFriendRequest() async {
        guard let uid = currentUid else { return }
        await MainActor.run { isToggling = true }
        do {
            try await firestoreService.denyFriendRequest(fromId: user.id, toId: uid)
            await MainActor.run { friendshipStatus = .notFriends }
        } catch {}
        await MainActor.run { isToggling = false }
    }

    func unfriend() async {
        guard let uid = currentUid else { return }
        await MainActor.run { isToggling = true }
        do {
            try await firestoreService.unfriend(currentUid: uid, otherUid: user.id)
            await MainActor.run {
                friendshipStatus = .notFriends
                friendCount = max(0, friendCount - 1)
            }
        } catch {}
        await MainActor.run { isToggling = false }
    }

    private func checkFriendshipStatus() async {
        guard let uid = currentUid else {
            await MainActor.run { isLoading = false }
            return
        }
        do {
            let status = try await firestoreService.getFriendshipStatus(currentUid: uid, otherUid: user.id)
            await MainActor.run {
                friendshipStatus = status
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func loadFriendCount() async {
        do {
            let count = try await firestoreService.fetchFriendCount(userId: user.id)
            await MainActor.run { friendCount = count }
        } catch {}
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
