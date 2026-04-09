//
//  AlbumDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct AlbumDetailView: View {
    @State private var viewModel: AlbumDetailViewModel
    init(album: AlbumResult) {
        _viewModel = State(initialValue: AlbumDetailViewModel(album: album))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album artwork
                AsyncImage(url: viewModel.largeImageUrl ?? viewModel.album.imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(maxWidth: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)

                // Album info
                VStack(spacing: 6) {
                    Text(viewModel.album.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(viewModel.album.artistName)
                        .font(.body)
                        .foregroundColor(.secondary)

                    if viewModel.album.albumType != "album" {
                        Text(viewModel.album.albumType == "single" ? "EP / Single" : "Compilation")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)

                // Average rating
                if let avg = viewModel.averageRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", avg))
                            .font(.headline)
                        Text("average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 20)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                } else {
                    // Track list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink(value: track) {
                                HStack(spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, alignment: .trailing)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.body)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                        if track.artistName != viewModel.album.artistName {
                                            Text(track.artistName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    if let r = viewModel.ratings[track.id] {
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                            Text(r == r.rounded() ? "\(Int(r))" : String(format: "%.1f", r))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }

                            if index < viewModel.tracks.count - 1 {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Album")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.refreshRatings() } }
    }
}
