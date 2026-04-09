//
//  AlbumResult.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation

struct AlbumResult: Identifiable, Hashable {
    let id: String
    let name: String
    let artistName: String
    let albumType: String
    let imageUrl: URL?
}
