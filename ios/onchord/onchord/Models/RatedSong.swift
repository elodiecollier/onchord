//
//  RatedSong.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct RatedSong: Identifiable {
    let id: String // review doc ID
    let trackId: String
    let trackName: String
    let artistName: String
    let albumName: String
    let albumImageUrl: URL?
    let rating: Double
}
