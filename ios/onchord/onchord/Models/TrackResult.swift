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
    let imageUrl: URL?
    let albumTrackCount: Int
}
