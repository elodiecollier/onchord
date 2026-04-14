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
            let hPad           = cardWidth * 0.07
            let cardCorner     = geo.size.width * 0.045
            let imageSize      = cardWidth * 0.40
            let imageCorner    = geo.size.width * 0.04
            // Tall enough to show the card including the save button when it appears.
            let carouselHeight = geo.size.height * 0.40

            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed header — stays put while content scrolls beneath it.
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
                            VStack(spacing: geo.size.height * 0.02) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: geo.size.width * 0.15))
                                    .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                Text("All caught up!")
                                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.055))
                                    .foregroundStyle(Color("greenLight"))
                                Text("No unrated recent listens")
                                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.038))
                                    .foregroundStyle(Color("blueLight").opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, minHeight: geo.size.height * 0.5)
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
                                        VStack(spacing: geo.size.height * 0.012) {
                                            AsyncImage(url: track.largeImageUrl ?? track.imageUrl) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                default:
                                                    RoundedRectangle(cornerRadius: imageCorner)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .overlay {
                                                            Image(systemName: "music.note")
                                                                .font(.system(size: imageSize * 0.22))
                                                                .foregroundColor(.gray)
                                                        }
                                                }
                                            }
                                            .frame(width: imageSize, height: imageSize)
                                            .clipShape(RoundedRectangle(cornerRadius: imageCorner))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: imageCorner)
                                                    .strokeBorder(Color("greenLight"), lineWidth: geo.size.width * 0.007)
                                            }
                                            .shadow(radius: 4)

                                            VStack(spacing: geo.size.height * 0.003) {
                                                Text(track.name)
                                                    .font(.custom("OpenSans-Bold", size: cardWidth * 0.1))
                                                    .foregroundStyle(Color("greenLight"))
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)

                                                Text(track.artistName)
                                                    .font(.custom("OpenSans-SemiBold", size: cardWidth * 0.08))
                                                    .foregroundStyle(Color("blueLight"))
                                                    .lineLimit(1)
                                            }

                                            StarRatingView(
                                                rating: track.id == viewModel.currentTrackId
                                                    ? $viewModel.rating
                                                    : .constant(0.0)
                                            )
                                            .scaleEffect(0.78)
                                            .frame(height: 30)

                                            if viewModel.rating > 0 && track.id == viewModel.currentTrackId {
                                                Button {
                                                    Task { await viewModel.saveIfRated(trackId: track.id) }
                                                } label: {
                                                    Text("SAVE")
                                                        .font(.custom("OpenSans-Bold", size: cardWidth * 0.052))
                                                        .foregroundStyle(Color("backgroundColorDark"))
                                                        .padding(.horizontal, cardWidth * 0.08)
                                                        .padding(.vertical, geo.size.height * 0.006)
                                                        .background(
                                                            BlueGreenDiagonalGradient.gradient
                                                                .clipShape(Capsule())
                                                        )
                                                }
                                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                            }
                                        }
                                        .padding(hPad)
                                        .frame(width: cardWidth)
                                        .background(
                                            Color("backgroundColorAccent").opacity(0.2)
                                                .clipShape(RoundedRectangle(cornerRadius: cardCorner))
                                        )
                                        .zIndex(track.id == viewModel.currentTrackId ? 1 : 0)
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
                            // Reset the draft rating when swiping to a different card.
                            .onChange(of: viewModel.currentTrackId) { viewModel.rating = 0 }
                        }

                        // Future sections go here
                        }
                    }
                    .scrollIndicators(.hidden)
                } // VStack (header + scroll)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
    }
}

#Preview {
    ActivityView()
}
