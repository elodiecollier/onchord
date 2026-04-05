//
//  FollowListView.swift
//  onchord
//
//  Created by Elodie Collier on 4/5/26.
//

import SwiftUI
import FirebaseFirestore

enum FollowListMode: Hashable {
    case followers(userId: String)
    case following(userId: String)
}

struct FollowListView: View {
    let mode: FollowListMode
    @State private var users: [UserResult] = []
    @State private var isLoading = true

    private var title: String {
        switch mode {
        case .followers: return "Followers"
        case .following: return "Following"
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if users.isEmpty {
                Text("No \(title.lowercased()) yet")
                    .foregroundColor(.secondary)
            } else {
                List(users) { user in
                    NavigationLink(value: user) {
                        HStack(spacing: 12) {
                            SearchArtworkView(url: user.profileImageUrl, isCircle: true)
                            Text(user.displayName)
                                .font(.body)
                                .lineLimit(1)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UserResult.self) { user in
            UserProfileView(user: user)
        }
        .task { await loadUsers() }
    }

    private func loadUsers() async {
        let db = Firestore.firestore()

        do {
            let snapshot: QuerySnapshot
            switch mode {
            case .followers(let userId):
                snapshot = try await db.collection("follows")
                    .whereField("followingId", isEqualTo: userId)
                    .getDocuments()
            case .following(let userId):
                snapshot = try await db.collection("follows")
                    .whereField("followerId", isEqualTo: userId)
                    .getDocuments()
            }

            let userIds: [String] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                switch mode {
                case .followers:
                    return data["followerId"] as? String
                case .following:
                    return data["followingId"] as? String
                }
            }

            var results: [UserResult] = []
            for uid in userIds {
                let userDoc = try await db.collection("users").document(uid).getDocument()
                guard let data = userDoc.data() else { continue }
                let displayName = data["displayName"] as? String ?? "Unknown"
                let profileImageUrl = (data["profileImageUrl"] as? String).flatMap { URL(string: $0) }
                results.append(UserResult(id: uid, displayName: displayName, profileImageUrl: profileImageUrl))
            }

            await MainActor.run {
                users = results
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
