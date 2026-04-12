//
//  ActivityView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        Text("Activity")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.06))
                            .foregroundStyle(Color("greenLight"))
                        Spacer()
                        NavigationLink(destination: NotificationsView(geo: geo)) {
                            Image(systemName: "bell")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width * 0.06)
                                .foregroundStyle(Color("blueLight"))
                        }
                    }
                    .padding(.top, geo.size.height * 0.07)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ActivityView()
}
