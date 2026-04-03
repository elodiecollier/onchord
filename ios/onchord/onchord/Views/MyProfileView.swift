//
//  MyProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RatedSong: Identifiable {
    let id: String // review doc ID
    let trackId: String
    let trackName: String
    let artistName: String
    let albumName: String
    let albumImageUrl: URL?
    let rating: Double
}

struct RatedAlbum: Identifiable {
    let id: String // albumName used as identifier
    let albumName: String
    let artistName: String
    let albumImageUrl: URL?
    let averageRating: Double
    let ratedCount: Int
}

struct MyProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var ratedSongs: [RatedSong] = []
    @State private var ratedAlbums: [RatedAlbum] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if ratedSongs.isEmpty {
                VStack(spacing: 12) {
                    Text("No ratings yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Search for songs and rate them to see your activity here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                List {
                    Section("Rated Songs") {
                        ForEach(ratedSongs) { song in
                            NavigationLink(value: TrackResult(
                                id: song.trackId,
                                name: song.trackName,
                                artistName: song.artistName,
                                albumName: song.albumName,
                                imageUrl: song.albumImageUrl
                            )) {
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
                            }
                        }
                    }

                    if !ratedAlbums.isEmpty {
                        Section("Rated Albums") {
                            ForEach(ratedAlbums) { album in
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
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationDestination(for: TrackResult.self) { track in
                    SongDetailView(track: track)
                }
            }
        }
        .navigationTitle(authManager.user?.displayName ?? "My Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Log out") {
                    authManager.logout()
                }
                .foregroundColor(.red)
            }
        }
        .task { await loadReviews() }
    }

    private func loadReviews() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            await MainActor.run { isLoading = false }
            return
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("reviews")
                .whereField("userId", isEqualTo: uid)
                .order(by: "updatedAt", descending: true)
                .getDocuments()

            var songs: [RatedSong] = []
            // Group by albumName for album aggregation
            var albumGroups: [String: (artistName: String, imageUrl: URL?, ratings: [Double])] = [:]

            for doc in snapshot.documents {
                let data = doc.data()
                guard let trackId = data["trackId"] as? String,
                      let trackName = data["trackName"] as? String,
                      let rating = data["rating"] as? Double else { continue }

                let artistName = data["artistName"] as? String ?? "Unknown Artist"
                let albumName = data["albumName"] as? String ?? ""
                let imageUrlString = data["albumImageUrl"] as? String ?? ""
                let imageUrl = URL(string: imageUrlString)

                songs.append(RatedSong(
                    id: doc.documentID,
                    trackId: trackId,
                    trackName: trackName,
                    artistName: artistName,
                    albumName: albumName,
                    albumImageUrl: imageUrl,
                    rating: rating
                ))

                if !albumName.isEmpty {
                    if var group = albumGroups[albumName] {
                        group.ratings.append(rating)
                        albumGroups[albumName] = group
                    } else {
                        albumGroups[albumName] = (artistName: artistName, imageUrl: imageUrl, ratings: [rating])
                    }
                }
            }

            // Build rated albums sorted by average rating descending
            var albums: [RatedAlbum] = albumGroups.map { name, group in
                let avg = group.ratings.reduce(0, +) / Double(group.ratings.count)
                return RatedAlbum(
                    id: name,
                    albumName: name,
                    artistName: group.artistName,
                    albumImageUrl: group.imageUrl,
                    averageRating: avg,
                    ratedCount: group.ratings.count
                )
            }
            albums.sort { $0.averageRating > $1.averageRating }

            await MainActor.run {
                ratedSongs = songs
                ratedAlbums = albums
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
