//
//  UserResult.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct UserResult: Identifiable, Hashable {
    let id: String
    let displayName: String
    let profileImageUrl: URL?
}
