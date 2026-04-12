//
//  SearchView.swift
//  onchord
//
//  Created by Elodie Collier on 4/2/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SearchView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(viewModel.searchMode == .music ? "Search music..." : "Search people...", text: $viewModel.query)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.clearQuery()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Picker("Search Mode", selection: $viewModel.searchMode) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if !viewModel.status.isEmpty {
                Text(viewModel.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            if viewModel.showHistory && !viewModel.searchHistory.isEmpty {
                List {
                    Section {
                        ForEach(viewModel.searchHistory, id: \.self) { term in
                            Button {
                                viewModel.triggerSearch(for: term)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.secondary)
                                    Text(term)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear") {
                                viewModel.clearHistory()
                            }
                            .font(.caption)
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
            } else if viewModel.searchMode == .people {
                if viewModel.hasSearched && viewModel.userResults.isEmpty {
                    Spacer()
                    Text("No people found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if !viewModel.userResults.isEmpty {
                    List(viewModel.userResults) { user in
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
                    .navigationDestination(for: UserResult.self) { user in
                        UserProfileView(user: user)
                    }
                } else {
                    Spacer()
                }
            } else if viewModel.hasSearched && viewModel.items.isEmpty {
                Spacer()
                Text("No results found")
                    .foregroundColor(.secondary)
                Spacer()
            } else if !viewModel.items.isEmpty {
                List(viewModel.items) { item in
                    switch item {
                    case .artist(let id, let name, let imageUrl):
                        NavigationLink(value: ArtistResult(id: id, name: name, imageUrl: imageUrl)) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: imageUrl, isCircle: true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text("Artist")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                    case .album(let id, let name, let artistName, let albumType, let imageUrl):
                        NavigationLink(value: AlbumResult(id: id, name: name, artistName: artistName, albumType: albumType, imageUrl: imageUrl)) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: imageUrl, isCircle: false)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.body)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        Text(artistName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        if albumType != "album" {
                                            Text("·")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(albumType == "single" ? "EP / Single" : "Compilation")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                        }

                    case .track(let track):
                        NavigationLink(value: track) {
                            HStack(spacing: 12) {
                                SearchArtworkView(url: track.imageUrl, isCircle: false)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.name)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(track.artistName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: TrackResult.self) { track in
                    SongDetailView(track: track)
                }
                .navigationDestination(for: AlbumResult.self) { album in
                    AlbumDetailView(album: album)
                }
                .navigationDestination(for: ArtistResult.self) { artist in
                    ArtistDetailView(artist: artist)
                }
            } else {
                Spacer()
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: FriendsRoute.self) { route in
            FollowListView(userId: route.userId)
        }
        .onAppear { viewModel.loadHistory() }
        .onChange(of: viewModel.query) { _, newValue in
            viewModel.onQueryChanged(newValue)
        }
        .onChange(of: viewModel.searchMode) { _, _ in
            viewModel.onSearchModeChanged()
        }
    }
}
