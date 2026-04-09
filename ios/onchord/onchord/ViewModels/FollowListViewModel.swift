//
//  FollowListViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

@Observable
final class FollowListViewModel {
    let mode: FollowListMode

    private(set) var users: [UserResult] = []
    private(set) var isLoading = true

    var title: String {
        switch mode {
        case .followers: return "Followers"
        case .following: return "Following"
        }
    }

    private let firestoreService = FirestoreService()

    init(mode: FollowListMode) {
        self.mode = mode
    }

    func load() async {
        do {
            let results = try await firestoreService.fetchFollowUsers(mode: mode)
            await MainActor.run {
                users = results
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
