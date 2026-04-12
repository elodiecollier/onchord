//
//  FriendshipStatus.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

enum FriendshipStatus {
    case notFriends
    case requestSent      // current user sent a request to this user
    case requestReceived  // this user sent a request to current user
    case friends
}

struct FriendsRoute: Hashable {
    let userId: String
}
