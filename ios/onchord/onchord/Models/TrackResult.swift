//
//  TrackResult.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct TrackResult: Identifiable, Hashable {
    let id: String
    let name: String
    let artistName: String
    let albumName: String
    let albumId: String?
    let albumType: String
    let imageUrl: URL?
    let largeImageUrl: URL?
    let albumTrackCount: Int
}
