//
//  RatingCountDisplayView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct RatingCountDisplayView: View {
    let ratingCountVal: String
    let ratingCountTitle: String
    let geo: GeometryProxy

    var body: some View {
        VStack {
            Text(ratingCountVal)
                .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                .bold()
                .foregroundStyle(Color("backgroundColorAccent"))
            Text(ratingCountTitle)
                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.02))
                .bold()
                .foregroundStyle(Color("backgroundColorAccent"))
            
        }
        .frame(width: geo.size.width * 0.15, height: geo.size.height * 0.05)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color("greenLight"), Color("blueLight")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}
