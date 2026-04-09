//
//  RatedAlbum.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct RatedAlbum: Identifiable {
    let id: String // albumName used as identifier
    let albumName: String
    let artistName: String
    let albumImageUrl: URL?
    let averageRating: Double
    let ratedCount: Int
}
