//
//  NotificationsViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import Foundation
import FirebaseAuth

@Observable
final class NotificationsViewModel {
    private(set) var pendingRequests: [UserResult] = []
    private(set) var isLoading = true

    private let firestoreService = FirestoreService()

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    func load() async {
        guard let uid = currentUid else {
            await MainActor.run { isLoading = false }
            return
        }
        do {
            let results = try await firestoreService.fetchIncomingFriendRequests(userId: uid)
            await MainActor.run {
                pendingRequests = results
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    func accept(user: UserResult) async {
        guard let uid = currentUid else { return }
        do {
            try await firestoreService.acceptFriendRequest(fromId: user.id, toId: uid)
            await MainActor.run {
                pendingRequests.removeAll { $0.id == user.id }
            }
        } catch {}
    }

    func deny(user: UserResult) async {
        guard let uid = currentUid else { return }
        do {
            try await firestoreService.denyFriendRequest(fromId: user.id, toId: uid)
            await MainActor.run {
                pendingRequests.removeAll { $0.id == user.id }
            }
        } catch {}
    }
}
