//
//  UserProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI

struct UserProfileView: View {
    @State private var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss

    init(user: UserResult) {
        _viewModel = State(initialValue: UserProfileViewModel(user: user))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        PrimaryBackNavigationButton(geo: geo)
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button(action: {
                                Task { await viewModel.toggleFollow() }
                            }) {
                                HStack {
                                    Text(viewModel.isFollowing ? "FOLLOWING" : "FOLLOW")
                                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                                    Image(systemName: viewModel.isFollowing ? "minus" : "plus")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geo.size.width * 0.035)
                                }
                                .foregroundStyle(viewModel.isFollowing ? Color("greenLight") : Color("blueLight"))
                                    .padding()
                                    .background((viewModel.isFollowing ? Color("greenDark") : Color("blueDark")).cornerRadius(20).opacity(0.2))
                                
                            }
                            .disabled(viewModel.isToggling)
                            .opacity(viewModel.isToggling ? 0.6 : 1.0)
                        }
                    }
                    .padding(geo.size.width * 0.01)
                    .padding(.top, geo.size.height * 0.05)
                    .padding(.horizontal)

                    ScrollView {
                        ProfileInfoView(
                            geo: geo,
                            songCount: viewModel.ratedSongs.count,
                            albumCount: viewModel.ratedAlbums.count,
                            displayName: viewModel.user.displayName,
                            profileImageUrl: viewModel.user.profileImageUrl
                        )
                        .padding(.horizontal)
                        ScrollableRatedSongsView(songs: viewModel.ratedSongs, geo: geo)
                            .padding()
                        ScrollableRatedAlbumView(albums: viewModel.ratedAlbums, geo: geo)
                            .padding(.horizontal)
                            .padding(.bottom, geo.size.height * 0.1)
                    }
                }
                .padding(.top, geo.size.height * 0.05)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                await viewModel.load()
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
        }
    }
}
