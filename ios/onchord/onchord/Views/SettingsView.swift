//
//  SettingsView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        GeometryReader { geo in
            let hPad = geo.size.width * 0.05
            let cardCorner: CGFloat = geo.size.width * 0.05

            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        PrimaryBackNavigationButton(geo: geo)
                        Spacer()
                        Text("Settings")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.045))
                            .foregroundStyle(Color("blueLight"))
                        Spacer()
                    }
                    .padding()

                    ScrollView {
                        VStack(spacing: geo.size.height * 0.012) {
                            Button {
                                authManager.logout()
                            } label: {
                                HStack {
                                    Text("Log Out")
                                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.038))
                                        .foregroundStyle(Color.red.opacity(0.85))
                                    Spacer()
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: geo.size.width * 0.038))
                                        .foregroundStyle(Color.red.opacity(0.85))
                                }
                                .padding(.horizontal, geo.size.width * 0.04)
                                .padding(.vertical, geo.size.height * 0.018)
                                .background(
                                    Color("backgroundColorAccent").opacity(0.2)
                                        .clipShape(RoundedRectangle(cornerRadius: cardCorner))
                                )
                            }
                        }
                        .padding(.horizontal, hPad)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
