//
//  SongCardView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct SongCardView: View {
    let song: RatedSong
    let geo: GeometryProxy

    private var ratingText: String {
        song.rating == song.rating.rounded()
            ? "\(Int(song.rating))"
            : String(format: "%.1f", song.rating)
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
                AsyncImage(url: song.albumImageUrl) { phase in
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
                        .foregroundStyle(Color("greenLight"))
                    Image(systemName: "star.fill")
                        .font(.system(size: geo.size.width * 0.025))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, badgePaddingH)
                .padding(.vertical, badgePaddingV)
                .background{
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(Color("backgroundColorDark"))
                }
                .offset(y: -badgeOffset)
            }
            .padding(.top, badgeOffset)

            Text(song.trackName)
                .font(.custom("OpenSans-Bold", size: geo.size.width * 0.03))
                .foregroundStyle(Color("greenLight"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cardWidth, alignment: .leading)

            Text(song.artistName)
                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.025))
                .foregroundStyle(Color("greenLight"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
    }
}
