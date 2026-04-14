//
//  ActivityView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct ActivityView: View {
    @State private var viewModel = ActivityViewModel()

    var body: some View {
        GeometryReader { geo in
            let cardWidth      = geo.size.width * 0.66
            let cardSpacing    = -geo.size.width * 0.06
            let sideMargin     = (geo.size.width - cardWidth) / 2
            let carouselHeight = geo.size.height * 0.40

            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Image("onchordLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.width * 0.07)
                            .frame(maxWidth: .infinity)
                        
                        HStack {
                            Spacer()
                            NavigationLink(destination: NotificationsView(geo: geo)) {
                                Image(systemName: "bell")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geo.size.width * 0.06)
                                    .foregroundStyle(Color("blueLight"))
                            }
                        }
                    }
                    .padding(.top, geo.size.height * 0.07)
                    .padding(.bottom)
                    .padding(.horizontal)
                    
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: geo.size.height * 0.5)
                            } else if viewModel.isDone {
                                Text("All recent listens have been rated!")
                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.028))
                                    .foregroundStyle(Color("backgroundColorDark"))
                                    .padding(.horizontal, geo.size.width * 0.04)
                                    .padding(.vertical, geo.size.height * 0.007)
                                    .background(
                                        BlueGreenDiagonalGradient.gradient
                                            .clipShape(Capsule())
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, geo.size.height * 0.01)
                                    .padding(.bottom, geo.size.height * 0.01)
                            } else {
                                Text("Rate Your Recent Listens")
                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                    .foregroundStyle(Color("blueLight"))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, geo.size.height * 0.01)
                                
                                ScrollView(.horizontal) {
                                    LazyHStack(spacing: cardSpacing) {
                                        ForEach(viewModel.unratedTracks) { track in
                                            let isActive = track.id == viewModel.currentTrackId
                                            RateRecentListenModal(
                                                track: track,
                                                isActive: isActive,
                                                rating: isActive ? $viewModel.rating : .constant(0.0),
                                                onSave: { await viewModel.saveIfRated(trackId: track.id) },
                                                geo: geo,
                                                cardWidth: cardWidth
                                            )
                                            .zIndex(isActive ? 1 : 0)
                                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                                content
                                                    .opacity(phase.isIdentity ? 1.0 : 0.55)
                                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.82)
                                            }
                                        }
                                    }
                                    .scrollTargetLayout()
                                    .padding(.horizontal, sideMargin)
                                }
                                .frame(height: carouselHeight)
                                .animation(.spring(duration: 0.35), value: viewModel.unratedTracks.map(\.id))
                                .scrollTargetBehavior(.viewAligned)
                                .scrollPosition(id: $viewModel.currentTrackId)
                                .scrollIndicators(.hidden)
                                .onChange(of: viewModel.currentTrackId) { viewModel.rating = 0 }
                            }
                            
                            if !viewModel.friendActivity.isEmpty {
                                VStack(alignment: .leading, spacing: geo.size.height * 0.016) {
                                    Text("From Your Friends")
                                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                        .foregroundStyle(Color("blueLight"))
                                        .frame(maxWidth: .infinity)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, geo.size.height * 0.025)
                                    
                                    ForEach(viewModel.friendActivity) { item in
                                        FriendActivityRow(item: item, geo: geo)
                                    }
                                }
                                .padding(.horizontal, geo.size.width * 0.05)
                                .padding(.bottom, geo.size.height * 0.02)
                            }
                        }
                        .padding(.bottom, geo.size.height * 0.14)
                    }
                    .refreshable { await viewModel.load(isRefresh: true) }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }
}
