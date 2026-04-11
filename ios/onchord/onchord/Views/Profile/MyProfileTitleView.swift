//
//  MyProfileTitleView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct MyProfileTitleView: View {
    let geo: GeometryProxy
    
    var body: some View {
        HStack {
            Text("My Profile")
                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.04))
                .bold()
                .foregroundStyle(Color("backgroundColorAccent"))
                .padding()
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
                    .foregroundStyle(Color("backgroundColorAccent"))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width * 0.04)
            }
            .padding()
        }
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
