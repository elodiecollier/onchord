//
//  FollowListView.swift
//  onchord
//
//  Created by Elodie Collier on 4/5/26.
//

import SwiftUI

struct FollowListView: View {
    @State private var viewModel: FollowListViewModel

    init(userId: String) {
        _viewModel = State(initialValue: FollowListViewModel(userId: userId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.users.isEmpty {
                Text("No friends yet")
                    .foregroundColor(.secondary)
            } else {
                List(viewModel.users) { user in
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
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UserResult.self) { user in
            UserProfileView(user: user)
        }
        .task { await viewModel.load() }
    }
}
