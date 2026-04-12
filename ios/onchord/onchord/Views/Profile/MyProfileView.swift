//
//  MyProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var viewModel = MyProfileViewModel()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()
                VStack {
                    MyProfileTitleView(geo: geo)
                        .padding(.top, geo.size.height * 0.05)
                        .padding()
                    ScrollView {
                        ProfileInfoView(
                            geo: geo,
                            songCount: viewModel.ratedSongs.count,
                            albumCount: viewModel.ratedAlbums.count,
                            displayName: authManager.user?.displayName ?? "",
                            profileImageUrl: nil,
                            friendCount: viewModel.friendCount,
                            userId: viewModel.currentUid ?? "",
                            isLoading: viewModel.isLoading
                        )
                        .padding(.horizontal)
                        ScrollableRatedSongsView(songs: viewModel.ratedSongs, geo: geo)
                            .padding()
                        ScrollableRatedAlbumView(albums: viewModel.ratedAlbums, geo: geo)
                            .padding(.horizontal)
                            .padding(.bottom, geo.size.height * 0.1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                await viewModel.load()
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: FriendsRoute.self) { route in
                FollowListView(userId: route.userId)
            }
        }
    }
}
