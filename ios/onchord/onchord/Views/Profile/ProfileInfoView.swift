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

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width * 0.28)
                .foregroundStyle(.white)
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
                    Text("Elodie Collier")
                        .padding(.trailing, geo.size.width * 0.01)
                    Spacer()
                }
                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.03))
                    .foregroundStyle(Color("greenLight"))
                HStack {
                    RatingCountDisplayView(ratingCountVal: songCount, ratingCountTitle: "Song Ratings", geo: geo)
                        .padding(.trailing, geo.size.width * 0.01)
                    RatingCountDisplayView(ratingCountVal: albumCount, ratingCountTitle: "Album Ratings", geo: geo)
                }
                .padding(.trailing, geo.size.width * 0.01)
                FriendsButton(friendsCount: 10, geo: geo)
                    .padding(.trailing, geo.size.width * 0.01)
            }
        }
        .padding()
        .background(Color("backgroundColorAccent").cornerRadius(20).opacity(0.5))
    }
}
