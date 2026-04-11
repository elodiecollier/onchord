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
                        ProfileInfoView(geo: geo, songCount: viewModel.ratedSongs.count, albumCount: viewModel.ratedAlbums.count)
                            .padding(.horizontal)
                        ScrollableRatedSongsView(songs: viewModel.ratedSongs, geo: geo)
                            .padding()
                        ScrollableRatedAlbumView(albums: viewModel.ratedAlbums, geo: geo)
                            .padding(.horizontal)
                            .padding(.bottom, geo.size.height * 0.1)
                    }
                }
//                            Group {
//                                if viewModel.isLoading {
//                                    ProgressView()
//                                } else {
//                                    List {
//                                        Section {
//                                            HStack(spacing: 0) {
//                                                NavigationLink(value: FollowListMode.followers(userId: viewModel.currentUid ?? "")) {
//                                                    VStack(spacing: 4) {
//                                                        Text("\(viewModel.followerCount)")
//                                                            .font(.title2.bold())
//                                                        Text("Followers")
//                                                            .font(.caption)
//                                                            .foregroundColor(.secondary)
//                                                    }
//                                                    .frame(maxWidth: .infinity)
//                                                }
//                                                .buttonStyle(.plain)
//                
//                                                NavigationLink(value: FollowListMode.following(userId: viewModel.currentUid ?? "")) {
//                                                    VStack(spacing: 4) {
//                                                        Text("\(viewModel.followingCount)")
//                                                            .font(.title2.bold())
//                                                        Text("Following")
//                                                            .font(.caption)
//                                                            .foregroundColor(.secondary)
//                                                    }
//                                                    .frame(maxWidth: .infinity)
//                                                }
//                                                .buttonStyle(.plain)
//                                            }
//                                            .padding(.vertical, 8)
//                                        }
//                
//                                        if viewModel.ratedSongs.isEmpty {
//                                            Section {
//                                                VStack(spacing: 12) {
//                                                    Text("No ratings yet")
//                                                        .font(.title3)
//                                                        .foregroundColor(.secondary)
//                                                    Text("Search for songs and rate them to see your activity here.")
//                                                        .font(.subheadline)
//                                                        .foregroundColor(.secondary)
//                                                        .multilineTextAlignment(.center)
//                                                }
//                                                .frame(maxWidth: .infinity)
//                                                .padding(.vertical, 20)
//                                            }
//                                        } else {
//                                            Section("Rated Songs") {
//                                                ForEach(viewModel.ratedSongs) { song in
//                                                    NavigationLink(value: TrackResult(
//                                                        id: song.trackId,
//                                                        name: song.trackName,
//                                                        artistName: song.artistName,
//                                                        albumName: song.albumName,
//                                                        imageUrl: song.albumImageUrl
//                                                    )) {
//                                                        HStack(spacing: 12) {
//                                                            SearchArtworkView(url: song.albumImageUrl, isCircle: false)
//                
//                                                            VStack(alignment: .leading, spacing: 2) {
//                                                                Text(song.trackName)
//                                                                    .font(.body)
//                                                                    .lineLimit(1)
//                                                                Text(song.artistName)
//                                                                    .font(.caption)
//                                                                    .foregroundColor(.secondary)
//                                                                    .lineLimit(1)
//                                                            }
//                
//                                                            Spacer()
//                
//                                                            HStack(spacing: 2) {
//                                                                Image(systemName: "star.fill")
//                                                                    .font(.caption2)
//                                                                    .foregroundColor(.yellow)
//                                                                Text(song.rating == song.rating.rounded()
//                                                                     ? "\(Int(song.rating))"
//                                                                     : String(format: "%.1f", song.rating))
//                                                                .font(.caption)
//                                                                .foregroundColor(.secondary)
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            }
//                
//                                            if !viewModel.ratedAlbums.isEmpty {
//                                                Section("Rated Albums") {
//                                                    ForEach(viewModel.ratedAlbums) { album in
//                                                        HStack(spacing: 12) {
//                                                            SearchArtworkView(url: album.albumImageUrl, isCircle: false)
//                
//                                                            VStack(alignment: .leading, spacing: 2) {
//                                                                Text(album.albumName)
//                                                                    .font(.body)
//                                                                    .lineLimit(1)
//                                                                Text(album.artistName)
//                                                                    .font(.caption)
//                                                                    .foregroundColor(.secondary)
//                                                                    .lineLimit(1)
//                                                            }
//                
//                                                            Spacer()
//                
//                                                            HStack(spacing: 2) {
//                                                                Image(systemName: "star.fill")
//                                                                    .font(.caption2)
//                                                                    .foregroundColor(.yellow)
//                                                                Text(String(format: "%.1f", album.averageRating))
//                                                                    .font(.caption)
//                                                                    .foregroundColor(.secondary)
//                                                                Text("(\(album.ratedCount))")
//                                                                    .font(.caption2)
//                                                                    .foregroundColor(.secondary)
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                    .listStyle(.insetGrouped)
//                                    .scrollContentBackground(.hidden)
//                                    .navigationDestination(for: TrackResult.self) { track in
//                                        SongDetailView(track: track)
//                                    }
//                                    .navigationDestination(for: FollowListMode.self) { mode in
//                                        FollowListView(mode: mode)
//                                    }
//                                }
//                            }
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
