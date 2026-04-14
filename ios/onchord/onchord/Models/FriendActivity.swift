//
//  FriendActivity.swift
//  onchord
//
//  Created by Elodie Collier on 4/13/26.
//

import Foundation

struct FriendActivity: Identifiable {
    let id: String          // review doc ID
    let friendId: String
    let displayName: String
    let profileImageUrl: URL?
    let trackId: String
    let trackName: String
    let artistName: String
    let albumName: String
    let albumImageUrl: URL?
    let albumLargeImageUrl: URL?
    let rating: Double
    let ratedAt: Date

    var asTrack: TrackResult {
        TrackResult(
            id: trackId,
            name: trackName,
            artistName: artistName,
            albumName: albumName,
            albumId: nil,
            albumType: "album",
            imageUrl: albumImageUrl,
            largeImageUrl: albumLargeImageUrl ?? albumImageUrl,
            albumTrackCount: 0
        )
    }

    var asFriend: UserResult {
        UserResult(id: friendId, displayName: displayName, profileImageUrl: profileImageUrl)
    }
}
