//
//  FollowListViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

@Observable
final class FollowListViewModel {
    let userId: String

    private(set) var users: [UserResult] = []
    private(set) var isLoading = true

    let title = "Friends"

    private let firestoreService = FirestoreService()

    init(userId: String) {
        self.userId = userId
    }

    func load() async {
        do {
            let results = try await firestoreService.fetchFriends(userId: userId)
            await MainActor.run {
                users = results
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
