//
//  ArtistDetailViewModel.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import Foundation
import FirebaseAuth

@Observable
final class ArtistDetailViewModel {
    let artist: ArtistResult

    private(set) var largeImageUrl: URL?
    private(set) var albums: [AlbumResult] = []
    private(set) var singles: [AlbumResult] = []
    private(set) var releaseYears: [String: String] = [:]
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    init(artist: ArtistResult) {
        self.artist = artist
    }

    func load() async {
        await loadArtistAlbums()
    }

    private func loadArtistAlbums() async {
        do {
            guard let user = Auth.auth().currentUser else {
                await MainActor.run { errorMessage = "Not signed in"; isLoading = false }
                return
            }

            let idToken = try await user.getIDToken()

            var request = URLRequest(
                url: URL(string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyArtistAlbums")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["artistId": artist.id])

            let (data, response) = try await URLSession.shared.data(for: request)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200...299).contains(httpStatus) else {
                let rawBody = String(data: data, encoding: .utf8) ?? "(non-utf8)"
                print("[ArtistDetail] HTTP \(httpStatus) full response: \(rawBody)")
                let errorBody = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                let msg: String
                if let spotifyErr = errorBody?["spotifyError"] as? [String: Any],
                   let errObj = spotifyErr["error"] as? [String: Any],
                   let message = errObj["message"] as? String {
                    let source = errorBody?["source"] as? String ?? "unknown"
                    msg = "\(source): \(message)"
                } else {
                    msg = errorBody?["error"] as? String ?? "Error \(httpStatus)"
                }
                await MainActor.run { errorMessage = msg; isLoading = false }
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                await MainActor.run { errorMessage = "Unexpected response"; isLoading = false }
                return
            }

            let artistObj = json["artist"] as? [String: Any]
            let images = artistObj?["images"] as? [[String: Any]] ?? []
            let largeUrl = images.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }

            let albumsObj = json["albums"] as? [String: Any]
            let albumItems = albumsObj?["items"] as? [[String: Any]] ?? []

            var albumsWithDate: [(AlbumResult, String)] = []
            var singlesWithDate: [(AlbumResult, String)] = []

            for item in albumItems {
                guard let id = item["id"] as? String,
                      let name = item["name"] as? String else { continue }
                let albumType = item["album_type"] as? String ?? "album"
                let artists = item["artists"] as? [[String: Any]] ?? []
                let artistName = artists.compactMap { $0["name"] as? String }.joined(separator: ", ")
                let itemImages = item["images"] as? [[String: Any]] ?? []
                let imageUrl = itemImages.first.flatMap { $0["url"] as? String }.flatMap { URL(string: $0) }
                let releaseDate = item["release_date"] as? String ?? ""

                let album = AlbumResult(
                    id: id, name: name,
                    artistName: artistName.isEmpty ? "Unknown Artist" : artistName,
                    albumType: albumType, imageUrl: imageUrl
                )

                if albumType == "album" {
                    albumsWithDate.append((album, releaseDate))
                } else {
                    singlesWithDate.append((album, releaseDate))
                }
            }

            albumsWithDate.sort { $0.1 > $1.1 }
            singlesWithDate.sort { $0.1 > $1.1 }

            var years: [String: String] = [:]
            for (album, date) in albumsWithDate + singlesWithDate {
                let year = String(date.prefix(4))
                if year.count == 4 { years[album.id] = year }
            }

            await MainActor.run {
                self.largeImageUrl = largeUrl
                self.albums = albumsWithDate.map(\.0)
                self.singles = singlesWithDate.map(\.0)
                self.releaseYears = years
                isLoading = false
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
