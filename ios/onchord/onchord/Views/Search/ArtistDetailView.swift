//
//  ArtistDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct ArtistDetailView: View {
    @State private var viewModel: ArtistDetailViewModel

    init(artist: ArtistResult) {
        _viewModel = State(initialValue: ArtistDetailViewModel(artist: artist))
    }

    var body: some View {
        ZStack {
            GradientBackgroundMain()
                .ignoresSafeArea()
        ScrollView {
            VStack(spacing: 20) {
                // Artist image
                AsyncImage(url: viewModel.largeImageUrl ?? viewModel.artist.imageUrl) { phase in
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
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(radius: 8)

                Text(viewModel.artist.name)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 20)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                } else {
                    if !viewModel.albums.isEmpty {
                        discographySection(title: "Albums", items: viewModel.albums)
                    }

                    if !viewModel.singles.isEmpty {
                        discographySection(title: "Singles & EPs", items: viewModel.singles)
                    }

                    if viewModel.albums.isEmpty && viewModel.singles.isEmpty {
                        Text("No releases found")
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Artist")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        } // ZStack
    }

    @ViewBuilder
    private func discographySection(title: String, items: [AlbumResult]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, album in
                    NavigationLink(value: album) {
                        HStack(spacing: 12) {
                            AsyncImage(url: album.imageUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                default:
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay {
                                            Image(systemName: "music.note")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.name)
                                    .font(.body)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                HStack(spacing: 4) {
                                    if let year = viewModel.releaseYears[album.id] {
                                        Text(year)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if album.albumType != "album" {
                                        Text("·")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(album.albumType == "single" ? "Single" : "Compilation")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }

                    if index < items.count - 1 {
                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
    }
}
