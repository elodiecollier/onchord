//
//  FriendActivityRow.swift
//  onchord
//
//  Created by Elodie Collier on 4/13/26.
//

import SwiftUI

struct FriendActivityRow: View {
    let item: FriendActivity
    let geo: GeometryProxy

    var body: some View {
        HStack(spacing: geo.size.width * 0.035) {
            NavigationLink(destination: UserProfileView(user: item.asFriend)) {
                AsyncImage(url: item.profileImageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Circle().fill(Color("backgroundColorAccent").opacity(0.4))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(Color("blueLight").opacity(0.5))
                                    .font(.system(size: geo.size.width * 0.04))
                            }
                    }
                }
                .frame(width: geo.size.width * 0.1, height: geo.size.width * 0.1)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: geo.size.height * 0.003) {
                HStack(spacing: geo.size.width * 0.012) {
                    Text(item.displayName)
                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.036))
                        .foregroundStyle(Color("greenLight"))
                    Text("rated")
                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.033))
                        .foregroundStyle(Color("blueLight").opacity(0.6))
                }

                Text(item.trackName)
                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.038))
                    .foregroundStyle(Color("blueLight"))
                    .lineLimit(1)

                Text(item.artistName)
                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.032))
                    .foregroundStyle(Color("blueLight").opacity(0.6))
                    .lineLimit(1)

                HStack(spacing: geo.size.width * 0.008) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: miniStarImage(for: star))
                            .font(.system(size: geo.size.width * 0.032))
                            .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink(destination: SongDetailView(track: item.asTrack)) {
                AsyncImage(url: item.albumImageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: geo.size.width * 0.02)
                            .fill(Color("backgroundColorAccent").opacity(0.3))
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundStyle(Color("blueLight").opacity(0.4))
                                    .font(.system(size: geo.size.width * 0.04))
                            }
                    }
                }
                .frame(width: geo.size.width * 0.14, height: geo.size.width * 0.14)
                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.02))
            }
        }
        .padding(geo.size.width * 0.04)
        .background(
            Color("backgroundColorAccent").opacity(0.15)
                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.04))
        )
    }

    private func miniStarImage(for position: Int) -> String {
        if item.rating >= Double(position) {
            return "star.fill"
        } else if item.rating >= Double(position) - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
