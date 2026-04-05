//
//  UserProfileView.swift
//  onchord
//
//  Created by Elodie Collier on 4/3/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    let user: UserResult
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var isToggling = false
    @State private var ratedSongs: [RatedSong] = []
    @State private var ratedAlbums: [RatedAlbum] = []
    @State private var isLoadingActivity = true

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    private var followDocId: String? {
        guard let uid = currentUid else { return nil }
        return "\(uid)_\(user.id)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile image
                AsyncImage(url: user.profileImageUrl) { phase in
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
                Text(user.displayName)
                    .font(.title2.bold())

                // Follow / Unfollow button
                if isLoading {
                    ProgressView()
                } else {
                    Button {
                        Task { await toggleFollow() }
                    } label: {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.headline)
                            .foregroundColor(isFollowing ? .primary : .white)
                            .frame(width: 160, height: 44)
                            .background(isFollowing ? Color(.systemGray5) : Color.blue)
                            .cornerRadius(22)
                    }
                    .disabled(isToggling)
                    .opacity(isToggling ? 0.6 : 1.0)
                }

                // Activity
                if isLoadingActivity {
                    ProgressView()
                        .padding(.top, 12)
                } else if ratedSongs.isEmpty {
                    Text("No ratings yet")
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Text("Rated Songs")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        ForEach(Array(ratedSongs.enumerated()), id: \.element.id) { index, song in
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

                            if index < ratedSongs.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }

                        if !ratedAlbums.isEmpty {
                            Text("Rated Albums")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 20)
                                .padding(.bottom, 8)

                            ForEach(Array(ratedAlbums.enumerated()), id: \.element.id) { index, album in
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

                                if index < ratedAlbums.count - 1 {
                                    Divider().padding(.leading, 68)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkFollowStatus()
            await loadUserActivity()
        }
    }

    private func checkFollowStatus() async {
        guard let docId = followDocId else {
            await MainActor.run { isLoading = false }
            return
        }

        do {
            let doc = try await Firestore.firestore()
                .collection("follows").document(docId).getDocument()
            await MainActor.run {
                isFollowing = doc.exists
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func toggleFollow() async {
        guard let uid = currentUid, let docId = followDocId else { return }

        await MainActor.run { isToggling = true }

        let db = Firestore.firestore()

        do {
            if isFollowing {
                try await db.collection("follows").document(docId).delete()
                await MainActor.run { isFollowing = false }
            } else {
                let data: [String: Any] = [
                    "followerId": uid,
                    "followingId": user.id,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                try await db.collection("follows").document(docId).setData(data)
                await MainActor.run { isFollowing = true }
            }
        } catch {
            // Silently fail — button state stays unchanged
        }

        await MainActor.run { isToggling = false }
    }

    private func loadUserActivity() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("reviews")
                .whereField("userId", isEqualTo: user.id)
                .order(by: "updatedAt", descending: true)
                .getDocuments()

            var songs: [RatedSong] = []
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
                isLoadingActivity = false
            }
        } catch {
            await MainActor.run { isLoadingActivity = false }
        }
    }
}
