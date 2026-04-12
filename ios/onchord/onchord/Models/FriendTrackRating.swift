//
//  FriendTrackRating.swift
//  onchord
//
//  Created by Elodie Collier on 4/12/26.
//

import Foundation

struct FriendTrackRating: Identifiable {
    let id: String // userId
    let displayName: String
    let profileImageUrl: URL?
    let rating: Double
}
