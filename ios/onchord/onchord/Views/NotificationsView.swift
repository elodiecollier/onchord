//
//  NotificationsView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct NotificationsView: View {
    let geo: GeometryProxy
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        ZStack {
            GradientBackgroundMain()
                .ignoresSafeArea()
            VStack {
                Text("Hello")
                Spacer()
            }
            VStack {
                HStack {
                    PrimaryBackNavigationButton(geo: geo)
                    Spacer()
                    Text("Notifications")
                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.05))
                        .foregroundStyle(Color("greenLight"))
                    Spacer()
                }
                .padding(.top, geo.size.height * 0.07)
                .padding(.horizontal)

                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, geo.size.height * 0.05)
                    } else if viewModel.pendingRequests.isEmpty {
                        Text("No pending friend requests")
                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.04))
                            .foregroundStyle(Color.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, geo.size.height * 0.05)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.pendingRequests) { user in
                                HStack {
                                    NavigationLink(destination: UserProfileView(user: user)) {
                                        HStack(spacing: 12) {
                                            SearchArtworkView(url: user.profileImageUrl, isCircle: true)
                                                .frame(width: geo.size.width * 0.12, height: geo.size.width * 0.12)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(user.displayName)
                                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                                    .foregroundStyle(.white)
                                                Text("wants to be friends")
                                                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                                    .foregroundStyle(Color.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    HStack(spacing: 8) {
                                        Button(action: { Task { await viewModel.accept(user: user) } }) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(Color("greenLight"))
                                                .padding(10)
                                                .background(Color("greenDark").cornerRadius(12).opacity(0.3))
                                        }
                                        Button(action: { Task { await viewModel.deny(user: user) } }) {
                                            Image(systemName: "xmark")
                                                .foregroundStyle(Color.red)
                                                .padding(10)
                                                .background(Color.red.cornerRadius(12).opacity(0.2))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color("backgroundColorAccent").cornerRadius(16).opacity(0.5))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }
}
