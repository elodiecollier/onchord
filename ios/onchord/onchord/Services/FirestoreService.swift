//
//  FirestoreService.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreService {

    private let db = Firestore.firestore()

    func isFollowing(docId: String) async throws -> Bool {
        let doc = try await db.collection("follows").document(docId).getDocument()
        return doc.exists
    }

    func follow(docId: String, followerId: String, followingId: String) async throws {
        let data: [String: Any] = [
            "followerId": followerId,
            "followingId": followingId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("follows").document(docId).setData(data)
    }

    func unfollow(docId: String) async throws {
        try await db.collection("follows").document(docId).delete()
    }

    func fetchFollowCounts(userId: String) async throws -> (followers: Int, following: Int) {
        let followersSnapshot = try await db.collection("follows")
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()
        let followingSnapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        return (followersSnapshot.documents.count, followingSnapshot.documents.count)
    }

    func fetchFollowUsers(mode: FollowListMode) async throws -> [UserResult] {
        let snapshot: QuerySnapshot
        switch mode {
        case .followers(let userId):
            snapshot = try await db.collection("follows")
                .whereField("followingId", isEqualTo: userId)
                .getDocuments()
        case .following(let userId):
            snapshot = try await db.collection("follows")
                .whereField("followerId", isEqualTo: userId)
                .getDocuments()
        }

        let userIds: [String] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            switch mode {
            case .followers:
                return data["followerId"] as? String
            case .following:
                return data["followingId"] as? String
            }
        }

        var results: [UserResult] = []
        for uid in userIds {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            guard let data = userDoc.data() else { continue }
            let displayName = data["displayName"] as? String ?? "Unknown"
            let profileImageUrl = (data["profileImageUrl"] as? String).flatMap { URL(string: $0) }
            results.append(UserResult(id: uid, displayName: displayName, profileImageUrl: profileImageUrl))
        }

        return results
    }

    func searchUsers(query: String, excludingUid: String) async throws -> [UserResult] {
        let lowered = query.lowercased()
        let snapshot = try await db.collection("users")
            .whereField("displayNameLower", isGreaterThanOrEqualTo: lowered)
            .whereField("displayNameLower", isLessThan: lowered + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let uid = doc.documentID
            guard uid != excludingUid else { return nil }
            let displayName = data["displayName"] as? String ?? "Unknown"
            let profileImageUrl = (data["profileImageUrl"] as? String).flatMap { URL(string: $0) }
            return UserResult(id: uid, displayName: displayName, profileImageUrl: profileImageUrl)
        }
    }

    func loadRating(docId: String) async throws -> Double? {
        let doc = try await db.collection("reviews").document(docId).getDocument()
        guard let data = doc.data(), let rating = data["rating"] as? Double else { return nil }
        return rating
    }

    func saveRating(_ value: Double, docId: String, userId: String, track: TrackResult) async throws {
        let data: [String: Any] = [
            "userId": userId,
            "trackId": track.id,
            "trackName": track.name,
            "artistName": track.artistName,
            "albumName": track.albumName,
            "albumImageUrl": track.imageUrl?.absoluteString ?? "",
            "albumTrackCount": track.albumTrackCount,
            "rating": value,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("reviews").document(docId).setData(data, merge: true)
    }

    func loadRatings(for tracks: [TrackResult], userId: String) async -> [String: Double] {
        var ratings: [String: Double] = [:]
        for track in tracks {
            let docId = "\(userId)_\(track.id)"
            if let rating = try? await loadRating(docId: docId) {
                ratings[track.id] = rating
            }
        }
        return ratings
    }

    func fetchReviews(userId: String) async throws -> (songs: [RatedSong], albums: [RatedAlbum]) {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        var songs: [RatedSong] = []
        var albumGroups: [String: (artistName: String, imageUrl: URL?, ratings: [Double], totalTrackCount: Int)] = [:]

        for doc in snapshot.documents {
            let data = doc.data()
            guard let trackId = data["trackId"] as? String,
                  let trackName = data["trackName"] as? String,
                  let rating = data["rating"] as? Double else { continue }

            let artistName = data["artistName"] as? String ?? "Unknown Artist"
            let albumName = data["albumName"] as? String ?? ""
            let imageUrlString = data["albumImageUrl"] as? String ?? ""
            let imageUrl = URL(string: imageUrlString)
            let albumTrackCount = data["albumTrackCount"] as? Int ?? 0

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
                    albumGroups[albumName] = (artistName: artistName, imageUrl: imageUrl, ratings: [rating], totalTrackCount: albumTrackCount)
                }
            }
        }

        var albums: [RatedAlbum] = albumGroups.compactMap { name, group in
            guard group.totalTrackCount > 0,
                  group.ratings.count == group.totalTrackCount else { return nil }
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

        return (songs, albums)
    }
}
