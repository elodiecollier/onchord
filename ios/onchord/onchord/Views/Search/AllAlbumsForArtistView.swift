//
//  AllAlbumsForArtistView.swift
//  onchord
//
//  Created by Elodie Collier on 4/12/26.
//

import SwiftUI

struct AllAlbumsForArtistView: View {
    @Bindable var viewModel: ArtistDetailViewModel

    var body: some View {
        GeometryReader { geo in
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

                        Text(viewModel.artist.name)
                            .font(.custom("OpenSans-Bold", size: geo.size.width * 0.065))
                            .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, hPad)

                        if viewModel.isLoadingAllAlbums {
                            ProgressView()
                                .padding(.top, geo.size.height * 0.02)
                        } else {
                            if !viewModel.allAlbums.isEmpty {
                                releaseSection(title: "Albums", items: viewModel.allAlbums, geo: geo, hPad: hPad, cardCorner: cardCorner)
                            }
                            if !viewModel.allSingles.isEmpty {
                                releaseSection(title: "Singles & EPs", items: viewModel.allSingles, geo: geo, hPad: hPad, cardCorner: cardCorner)
                            }
                            if viewModel.allAlbums.isEmpty && viewModel.allSingles.isEmpty {
                                Text("No releases found")
                                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                    .foregroundStyle(Color("blueLight").opacity(0.7))
                                    .padding(.top, geo.size.height * 0.02)
                            }
                        }
                    }
                    .padding(.top, geo.size.height * 0.03)
                    .padding(.bottom, geo.size.height * 0.05)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadAllAlbums() }
        }
    }

    @ViewBuilder
    private func releaseSection(title: String, items: [AlbumResult], geo: GeometryProxy, hPad: CGFloat, cardCorner: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: geo.size.height * 0.012) {
            Text(title)
                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                .foregroundStyle(Color("blueLight"))
                .padding(.horizontal, hPad)

            LazyVStack(spacing: geo.size.height * 0.01) {
                ForEach(items, id: \.id) { album in
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
                                HStack(spacing: geo.size.width * 0.015) {
                                    if let year = viewModel.allReleaseYears[album.id] {
                                        Text(year)
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                            .foregroundStyle(Color("blueLight").opacity(0.6))
                                    }
                                    if album.albumType != "album" {
                                        Text("·")
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                            .foregroundStyle(Color("blueLight").opacity(0.6))
                                        Text(album.albumType == "single" ? "Single" : "Compilation")
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                            .foregroundStyle(Color("greenLight"))
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
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
