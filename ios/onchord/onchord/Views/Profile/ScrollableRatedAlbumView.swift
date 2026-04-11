//
//  ScrollableRatedAlbumView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct ScrollableRatedAlbumView: View {
    let albums: [RatedAlbum]
    let geo: GeometryProxy

    private var recentAlbums: [RatedAlbum] {
        Array(albums.prefix(10))
    }

    var body: some View {
        VStack {
            HStack {
                Text("RECENT ALBUM RATINGS")
                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                    .foregroundStyle(Color("blueLight"))
                    .padding()
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(recentAlbums) { album in
                        AlbumCardView(album: album, geo: geo)
                    }
                }
                .padding(geo.size.width * 0.01)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color("backgroundColorAccent").cornerRadius(20).opacity(0.5))
    }
}

private struct AlbumCardView: View {
    let album: RatedAlbum
    let geo: GeometryProxy

    private var ratingText: String {
        album.averageRating == album.averageRating.rounded()
            ? "\(Int(album.averageRating))"
            : String(format: "%.1f", album.averageRating)
    }

    private var cardWidth: CGFloat { geo.size.width * 0.28 }
    private var badgePaddingH: CGFloat { geo.size.width * 0.018 }
    private var badgePaddingV: CGFloat { geo.size.width * 0.01 }
    private var badgeOffset: CGFloat { geo.size.width * 0.035 }
    private var cardCornerRadius: CGFloat { geo.size.width * 0.025 }
    private var cardSpacing: CGFloat { geo.size.width * 0.01 }

    var body: some View {
        VStack(alignment: .leading, spacing: cardSpacing) {
            ZStack(alignment: .top) {
                AsyncImage(url: album.albumImageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: geo.size.width * 0.06))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(width: cardWidth, height: cardWidth)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))

                HStack {
                    Text(ratingText)
                        .font(.custom("OpenSans-Bold", size: geo.size.width * 0.03))
                        .foregroundStyle(Color("blueLight"))
                    Image(systemName: "star.fill")
                        .font(.system(size: geo.size.width * 0.025))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, badgePaddingH)
                .padding(.vertical, badgePaddingV)
                .background {
                    RoundedRectangle(cornerRadius: cardCornerRadius)
                        .foregroundStyle(Color("backgroundColorDark"))
                }
                .offset(y: -badgeOffset)
            }
            .padding(.top, badgeOffset)

            Text(album.albumName)
                .font(.custom("OpenSans-Bold", size: geo.size.width * 0.03))
                .foregroundStyle(Color("blueLight"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cardWidth, alignment: .leading)

            Text(album.artistName)
                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.025))
                .foregroundStyle(Color("blueLight"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
    }
}
