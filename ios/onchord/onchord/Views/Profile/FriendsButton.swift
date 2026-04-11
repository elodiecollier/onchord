//
//  FriendsButton.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct FriendsButton: View {
    let friendsCount: Int
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text("\(friendsCount) friends")
                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.035))
                .foregroundStyle(Color("blueLight"))
            Spacer()
            Image(systemName: "arrow.forward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width * 0.03)
                .foregroundStyle(Color("blueLight"))
        }
        .padding()
        .background(Color("blueDark").cornerRadius(20).opacity(0.5))
    }
}
