//
//  UserProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI

struct UserProfileView: View {
    @State private var viewModel: UserProfileViewModel
    @State private var showUnfriendAlert = false
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
                            friendshipButton(geo: geo)
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
                            profileImageUrl: viewModel.user.profileImageUrl,
                            friendCount: viewModel.friendCount,
                            userId: viewModel.user.id,
                            isLoading: viewModel.isLoadingActivity
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

    @ViewBuilder
    private func friendshipButton(geo: GeometryProxy) -> some View {
        switch viewModel.friendshipStatus {
        case .notFriends:
            Button(action: { Task { await viewModel.sendFriendRequest() } }) {
                HStack {
                    Text("ADD FRIEND")
                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width * 0.04)
                }
                .foregroundStyle(Color("blueLight"))
                .padding()
                .background(Color("blueDark").cornerRadius(20).opacity(0.2))
            }
            .disabled(viewModel.isToggling)
            .opacity(viewModel.isToggling ? 0.6 : 1.0)

        case .requestSent:
            Button(action: { Task { await viewModel.cancelFriendRequest() } }) {
                HStack {
                    Text("REQUESTED")
                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                    Image(systemName: "clock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width * 0.035)
                }
                .foregroundStyle(Color.gray)
                .padding()
                .background(Color.gray.cornerRadius(20).opacity(0.2))
            }
            .disabled(viewModel.isToggling)
            .opacity(viewModel.isToggling ? 0.6 : 1.0)

        case .requestReceived:
            HStack(spacing: 8) {
                Button(action: { Task { await viewModel.acceptFriendRequest() } }) {
                    HStack {
                        Text("ACCEPT")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                        Image(systemName: "checkmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width * 0.035)
                    }
                    .foregroundStyle(Color("greenLight"))
                    .padding()
                    .background(Color("greenDark").cornerRadius(20).opacity(0.2))
                }
                Button(action: { Task { await viewModel.denyFriendRequest() } }) {
                    HStack {
                        Text("DENY")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width * 0.035)
                    }
                    .foregroundStyle(Color.red)
                    .padding()
                    .background(Color.red.cornerRadius(20).opacity(0.2))
                }
            }
            .disabled(viewModel.isToggling)
            .opacity(viewModel.isToggling ? 0.6 : 1.0)

        case .friends:
            Button(action: { showUnfriendAlert = true }) {
                HStack {
                    Text("FRIENDS")
                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width * 0.035)
                }
                .foregroundStyle(Color("greenLight"))
                .padding()
                .background(Color("greenDark").cornerRadius(20).opacity(0.2))
            }
            .disabled(viewModel.isToggling)
            .opacity(viewModel.isToggling ? 0.6 : 1.0)
            .alert("Remove Friend", isPresented: $showUnfriendAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove Friend", role: .destructive) {
                    Task { await viewModel.unfriend() }
                }
            } message: {
                Text("Are you sure you want to remove \(viewModel.user.displayName) as a friend?")
            }
        }
    }
}
