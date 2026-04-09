//
//  FollowListMode.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

enum FollowListMode: Hashable {
    case followers(userId: String)
    case following(userId: String)
}
