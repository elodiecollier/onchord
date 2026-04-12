//
//  ArtistDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct ArtistDetailView: View {
    @State private var viewModel: ArtistDetailViewModel

    init(artist: ArtistResult) {
        _viewModel = State(initialValue: ArtistDetailViewModel(artist: artist))
    }

    var body: some View {
        GeometryReader { geo in
            let imageSize = geo.size.width * 0.45
            let hPad = geo.size.width * 0.05
            let cardCorner: CGFloat = geo.size.width * 0.05

            ZStack {
                GradientBackgroundMain()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: geo.size.height * 0.025) {

                        HStack {
                            PrimaryBackNavigationButton(geo: geo)
                            Spacer()
                        }
                        .padding(.horizontal, hPad)

                        AsyncImage(url: viewModel.largeImageUrl ?? viewModel.artist.imageUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: geo.size.width * 0.12))
                                            .foregroundColor(.gray)
                                    }
                            }
                        }
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(BlueGreenDiagonalGradient.gradient, lineWidth: geo.size.width * 0.012)
                        }
                        .shadow(radius: 8)

                        // Artist name
                        Text(viewModel.artist.name)
                            .font(.custom("OpenSans-Bold", size: geo.size.width * 0.07))
                            .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, hPad)

                        // Your Stats section
                        statsSection(geo: geo, hPad: hPad, cardCorner: cardCorner)

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, geo.size.height * 0.02)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                .foregroundStyle(Color("blueLight").opacity(0.7))
                                .padding(.horizontal, hPad)
                        } else {
                            discographySection(geo: geo, hPad: hPad, cardCorner: cardCorner)
                        }
                    }
                    .padding(.top, geo.size.height * 0.03)
                    .padding(.bottom, geo.size.height * 0.05)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .onAppear { Task { await viewModel.refreshStats() } }
        }
    }

    @ViewBuilder
    private func statsSection(geo: GeometryProxy, hPad: CGFloat, cardCorner: CGFloat) -> some View {
        VStack(spacing: geo.size.height * 0.015) {
            Text("Your Stats")
                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                .foregroundStyle(Color("blueLight"))
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: geo.size.width * 0.03) {
                VStack(spacing: geo.size.height * 0.006) {
                    Text(viewModel.songsRatedPercent)
                        .font(.custom("OpenSans-Bold", size: geo.size.width * 0.065))
                        .foregroundStyle(Color("backgroundColorAccent"))
                    Text("Songs Rated")
                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                        .foregroundStyle(Color("backgroundColorAccent").opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, geo.size.height * 0.02)
                .background(BlueGreenDiagonalGradient.gradient)
                .clipShape(RoundedRectangle(cornerRadius: cardCorner))

                VStack(spacing: geo.size.height * 0.006) {
                    Text(viewModel.albumsRatedDisplay)
                        .font(.custom("OpenSans-Bold", size: geo.size.width * 0.065))
                        .foregroundStyle(Color("backgroundColorAccent"))
                    Text("Albums Rated")
                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                        .foregroundStyle(Color("backgroundColorAccent").opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, geo.size.height * 0.02)
                .background(BlueGreenDiagonalGradient.gradient)
                .clipShape(RoundedRectangle(cornerRadius: cardCorner))
            }

            HStack {
                Text("Average Rating")
                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.038))
                    .foregroundStyle(Color("backgroundColorAccent"))
                Spacer()
                if let avg = viewModel.averageArtistRating {
                    HStack(spacing: geo.size.width * 0.015) {
                        Text(avg == avg.rounded() ? "\(Int(avg))" : String(format: "%.1f", avg))
                            .font(.custom("OpenSans-Bold", size: geo.size.width * 0.042))
                            .foregroundStyle(Color("backgroundColorAccent"))
                        Image(systemName: "star")
                            .font(.system(size: geo.size.width * 0.035))
                            .foregroundStyle(Color("backgroundColorAccent"))
                    }
                } else {
                    Text("—")
                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.038))
                        .foregroundStyle(Color("backgroundColorAccent").opacity(0.5))
                }
            }
            .padding(.horizontal, geo.size.width * 0.04)
            .padding(.vertical, geo.size.height * 0.018)
            .frame(maxWidth: .infinity)
            .background(BlueGreenDiagonalGradient.gradient)
            .clipShape(RoundedRectangle(cornerRadius: cardCorner))
        }
        .padding(geo.size.width * 0.04)
        .background(Color("backgroundColorAccent").opacity(0.2).clipShape(RoundedRectangle(cornerRadius: cardCorner)))
        .padding(.horizontal, hPad)
    }

    @ViewBuilder
    private func discographySection(geo: GeometryProxy, hPad: CGFloat, cardCorner: CGFloat) -> some View {
        let previewAlbums = Array(viewModel.albums.prefix(5))
        let hasMore = !viewModel.albums.isEmpty || !viewModel.singles.isEmpty

        VStack(alignment: .leading, spacing: geo.size.height * 0.012) {
            HStack {
                Text("Releases")
                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                    .foregroundStyle(Color("blueLight"))
                Spacer()
                if hasMore {
                    NavigationLink {
                        AllAlbumsForArtistView(viewModel: viewModel)
                    } label: {
                        Text("View All")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.032))
                            .foregroundStyle(Color("blueLight"))
                            .padding(.horizontal, geo.size.width * 0.035)
                            .padding(.vertical, geo.size.height * 0.008)
                            .background(Color("blueDark").cornerRadius(20).opacity(0.2))
                    }
                }
            }
            .padding(.horizontal, hPad)

            if previewAlbums.isEmpty {
                Text("No albums found")
                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                    .foregroundStyle(Color("blueLight").opacity(0.7))
                    .padding(.horizontal, hPad)
            } else {
                VStack(spacing: geo.size.height * 0.01) {
                    ForEach(previewAlbums, id: \.id) { album in
                        NavigationLink(value: album) {
                            HStack(spacing: geo.size.width * 0.03) {
                                AsyncImage(url: album.imageUrl) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    default:
                                        RoundedRectangle(cornerRadius: geo.size.width * 0.015)
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay {
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: geo.size.width * 0.04))
                                            }
                                    }
                                }
                                .frame(width: geo.size.width * 0.12, height: geo.size.width * 0.12)
                                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.02))

                                VStack(alignment: .leading, spacing: geo.size.height * 0.004) {
                                    Text(album.name)
                                        .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.038))
                                        .lineLimit(1)
                                        .foregroundStyle(Color("blueLight"))
                                    if let year = viewModel.releaseYears[album.id] {
                                        Text(year)
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                            .foregroundStyle(Color("blueLight").opacity(0.6))
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: geo.size.width * 0.035))
                                    .foregroundStyle(Color("blueLight").opacity(0.5))
                            }
                            .padding(.horizontal, hPad)
                            .padding(.vertical, geo.size.height * 0.012)
                            .background(
                                Color("backgroundColorAccent").opacity(0.2)
                                    .clipShape(RoundedRectangle(cornerRadius: cardCorner))
                            )
                        }
                        .padding(.horizontal, hPad)
                    }
                }
            }
        }
    }
}
