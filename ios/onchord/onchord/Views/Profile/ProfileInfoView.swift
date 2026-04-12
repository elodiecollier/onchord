//
//  ProfileInfoView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct ProfileInfoView: View {
    let geo: GeometryProxy
    let songCount: Int
    let albumCount: Int
    let displayName: String
    let profileImageUrl: URL?
    let friendCount: Int
    let userId: String
    let isLoading: Bool

    var body: some View {
        HStack {
            AsyncImage(url: profileImageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: geo.size.width * 0.28, height: geo.size.width * 0.28)
            .clipShape(Circle())
            .padding(geo.size.width * 0.01)
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("greenLight"), Color("blueLight")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            VStack {
                HStack {
                    Text(displayName)
                        .padding(.trailing, geo.size.width * 0.01)
                    Spacer()
                }
                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.03))
                    .foregroundStyle(Color("greenLight"))
                HStack {
                    RatingCountDisplayView(ratingCountVal: isLoading ? "—" : "\(songCount)", ratingCountTitle: "Song Ratings", geo: geo)
                        .padding(.trailing, geo.size.width * 0.01)
                    RatingCountDisplayView(ratingCountVal: isLoading ? "—" : "\(albumCount)", ratingCountTitle: "Album Ratings", geo: geo)
                }
                .padding(.trailing, geo.size.width * 0.01)
                NavigationLink(value: FriendsRoute(userId: userId)) {
                    FriendsButton(friendsCount: friendCount, isLoading: isLoading, geo: geo)
                        .padding(.trailing, geo.size.width * 0.01)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color("backgroundColorAccent").cornerRadius(20).opacity(0.5))
    }
}
