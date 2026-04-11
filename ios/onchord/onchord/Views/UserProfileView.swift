//
//  UserProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI

struct UserProfileView: View {
    @State private var viewModel: UserProfileViewModel
    init(user: UserResult) {
        _viewModel = State(initialValue: UserProfileViewModel(user: user))
    }

    var body: some View {
        ZStack {
            GradientBackgroundMain()
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Profile image
                    AsyncImage(url: viewModel.user.profileImageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                }
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    
                    // Display name
                    Text(viewModel.user.displayName)
                        .font(.title2.bold())
                    
                    // Follow / Unfollow button
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await viewModel.toggleFollow() }
                        } label: {
                            Text(viewModel.isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .foregroundColor(viewModel.isFollowing ? .primary : .white)
                                .frame(width: 160, height: 44)
                                .background(viewModel.isFollowing ? Color(.systemGray5) : Color.blue)
                                .cornerRadius(22)
                        }
                        .disabled(viewModel.isToggling)
                        .opacity(viewModel.isToggling ? 0.6 : 1.0)
                    }
                    
                    // Activity
                    if viewModel.isLoadingActivity {
                        ProgressView()
                            .padding(.top, 12)
                    } else if viewModel.ratedSongs.isEmpty {
                        Text("No ratings yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            Text("Rated Songs")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            ForEach(Array(viewModel.ratedSongs.enumerated()), id: \.element.id) { index, song in
                                HStack(spacing: 12) {
                                    SearchArtworkView(url: song.albumImageUrl, isCircle: false)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.trackName)
                                            .font(.body)
                                            .lineLimit(1)
                                        Text(song.artistName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                        Text(song.rating == song.rating.rounded()
                                             ? "\(Int(song.rating))"
                                             : String(format: "%.1f", song.rating))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                
                                if index < viewModel.ratedSongs.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                            
                            if !viewModel.ratedAlbums.isEmpty {
                                Text("Rated Albums")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                    .padding(.bottom, 8)
                                
                                ForEach(Array(viewModel.ratedAlbums.enumerated()), id: \.element.id) { index, album in
                                    HStack(spacing: 12) {
                                        SearchArtworkView(url: album.albumImageUrl, isCircle: false)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(album.albumName)
                                                .font(.body)
                                                .lineLimit(1)
                                            Text(album.artistName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                            Text(String(format: "%.1f", album.averageRating))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("(\(album.ratedCount))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                    if index < viewModel.ratedAlbums.count - 1 {
                                        Divider().padding(.leading, 68)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .ignoresSafeArea()
    }
}
