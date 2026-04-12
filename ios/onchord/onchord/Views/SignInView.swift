//
//  SignInView.swift
//  onchord
//
//  Created by Elodie Collier on 4/12/26.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BlueGreenDiagonalGradient.gradient
                    .ignoresSafeArea()

                // Zoomed-in icon
                Image("onchordIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width * 2.7, height: geo.size.width * 2.7)
                    .clipped()

                // Title — centered independently
                VStack {
                    Spacer()
                    Text("ONCHORD")
                        .font(.custom("OpenSans-ExtraBold", size: geo.size.width * 0.12))
                        .foregroundStyle(Color("backgroundColorAccent"))
                        .padding(.bottom)
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)

                // Button — pinned to bottom independently
                VStack {
                    Spacer()
                    VStack(spacing: geo.size.height * 0.015) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(Color("backgroundColorAccent"))
                                .scaleEffect(1.2)
                        } else {
                            Button {
                                authManager.login()
                            } label: {
                                Text("SIGN IN WITH SPOTIFY")
                                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.042))
                                    .foregroundStyle(Color("backgroundColorAccent"))
                                    .padding(.vertical, geo.size.height * 0.02)
                                    .padding(.horizontal, geo.size.width * 0.12)
                                    .background(
                                        Color("greenDark")
                                            .clipShape(Capsule())
                                    )
                            }
                        }

                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                .foregroundStyle(Color("backgroundColorAccent").opacity(0.75))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, geo.size.width * 0.1)
                        }
                    }
                    .padding(.bottom, geo.size.height * 0.12)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
}
