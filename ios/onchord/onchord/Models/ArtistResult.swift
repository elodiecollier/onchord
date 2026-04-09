//
//  ArtistResult.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct ArtistResult: Identifiable, Hashable {
    let id: String
    let name: String
    let imageUrl: URL?
}
