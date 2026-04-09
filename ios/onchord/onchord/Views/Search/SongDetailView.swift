//
//  SongDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct SongDetailView: View {
    @State private var viewModel: SongDetailViewModel

    init(track: TrackResult) {
        _viewModel = State(initialValue: SongDetailViewModel(track: track))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Album art
                AsyncImage(url: viewModel.track.imageUrl) { phase in
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

                // Song info
                VStack(spacing: 6) {
                    Text(viewModel.track.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(viewModel.track.artistName)
                        .font(.body)
                        .foregroundColor(.secondary)

                    if !viewModel.track.albumName.isEmpty {
                        Text(viewModel.track.albumName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Rating
                VStack(spacing: 8) {
                    Text("Your Rating")
                        .font(.headline)

                    StarRatingView(rating: $viewModel.rating)

                    if viewModel.rating > 0 {
                        Text(viewModel.formattedRating)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.isSaving {
                    ProgressView()
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Rate Song")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadRating() }
        .onChange(of: viewModel.rating) { _, newValue in
            Task { await viewModel.saveRating(newValue) }
        }
    }
}
