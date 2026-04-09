//
//  SearchItem.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

enum SearchItem: Identifiable {
    case artist(id: String, name: String, imageUrl: URL?)
    case album(id: String, name: String, artistName: String, albumType: String, imageUrl: URL?)
    case track(TrackResult)

    var id: String {
        switch self {
        case .artist(let id, _, _): return "artist-\(id)"
        case .album(let id, _, _, _, _): return "album-\(id)"
        case .track(let t): return "track-\(t.id)"
        }
    }

    var name: String {
        switch self {
        case .artist(_, let name, _): return name
        case .album(_, let name, _, _, _): return name
        case .track(let t): return t.name
        }
    }
}
