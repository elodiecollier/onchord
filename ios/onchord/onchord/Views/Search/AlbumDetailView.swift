//
//  AlbumDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct AlbumDetailView: View {
    @State private var viewModel: AlbumDetailViewModel
    init(album: AlbumResult) {
        _viewModel = State(initialValue: AlbumDetailViewModel(album: album))
    }

    var body: some View {
        GeometryReader { geo in
        let imageSize = geo.size.width * 0.7
        let cornerRadius = geo.size.width * 0.08
        let cardStart = imageSize * 0.55
        let hPad = geo.size.width * 0.05
        let cardCorner: CGFloat = geo.size.width * 0.05

        ZStack {
            GradientBackgroundMain()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: geo.size.height * 0.02) {

                    HStack {
                        PrimaryBackNavigationButton(geo: geo)
                        Spacer()
                    }
                    .padding(.horizontal, hPad)

                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: cardStart)
                            Color("backgroundColorAccent").opacity(0.2)
                                .clipShape(RoundedRectangle(cornerRadius: cardCorner))
                        }

                        VStack(spacing: 0) {
                            let badgeOffset = geo.size.width * 0.08

                            ZStack(alignment: .top) {
                                AsyncImage(url: viewModel.largeImageUrl ?? viewModel.album.imageUrl) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    default:
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay {
                                                Image(systemName: "music.note")
                                                    .font(.system(size: geo.size.width * 0.12))
                                                    .foregroundColor(.gray)
                                            }
                                    }
                                }
                                .frame(width: imageSize, height: imageSize)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                .overlay {
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .strokeBorder(Color("blueLight"), lineWidth: geo.size.width * 0.012)
                                }
                                .shadow(radius: 8)

                                if let avg = viewModel.averageRating {
                                    HStack(spacing: geo.size.width * 0.02) {
                                        Text(avg == avg.rounded() ? "\(Int(avg))" : String(format: "%.1f", avg))
                                            .font(.custom("OpenSans-Bold", size: geo.size.width * 0.07))
                                            .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                        Image(systemName: "star.fill")
                                            .font(.system(size: geo.size.width * 0.058))
                                            .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                    }
                                    .padding(.horizontal, geo.size.width * 0.05)
                                    .padding(.vertical, geo.size.width * 0.028)
                                    .background {
                                        RoundedRectangle(cornerRadius: geo.size.width * 0.06)
                                            .foregroundStyle(Color("backgroundColorDark"))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: geo.size.width * 0.06)
                                                    .strokeBorder(Color("blueLight"), lineWidth: geo.size.width * 0.005)
                                            }
                                    }
                                    .offset(y: -badgeOffset)
                                }
                            }
                            .padding(.top, badgeOffset)

                            VStack(spacing: geo.size.height * 0.008) {
                                Text(viewModel.album.name)
                                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.055))
                                    .foregroundStyle(Color("blueLight"))
                                    .multilineTextAlignment(.center)

                                Text(viewModel.album.artistName)
                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                    .foregroundStyle(Color("blueLight"))

                                if viewModel.album.albumType != "album" {
                                    Text(viewModel.album.albumType == "single" ? "EP / Single" : "Compilation")
                                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                        .foregroundStyle(Color("blueLight").opacity(0.7))
                                }
                            }
                            .padding(.horizontal, hPad)
                            .padding(.vertical, geo.size.height * 0.02)
                        }
                    }
                    .padding(.horizontal, hPad)

                    if viewModel.isLoading {
                        ProgressView()
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                            .foregroundStyle(Color("blueLight").opacity(0.7))
                            .padding(.horizontal, hPad)
                    } else {
                        LazyVStack(spacing: geo.size.height * 0.012) {
                            ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                                NavigationLink(value: track) {
                                    HStack(spacing: geo.size.width * 0.03) {
                                        Text("\(index + 1)")
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                            .foregroundStyle(Color("blueLight").opacity(0.6))
                                            .frame(width: geo.size.width * 0.06, alignment: .trailing)

                                        VStack(alignment: .leading, spacing: geo.size.height * 0.004) {
                                            Text(track.name)
                                                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.038))
                                                .foregroundStyle(Color("greenLight"))
                                                .lineLimit(1)
                                            if track.artistName != viewModel.album.artistName {
                                                Text(track.artistName)
                                                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                                                    .foregroundStyle(Color("blueLight").opacity(0.7))
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        if let r = viewModel.ratings[track.id] {
                                            HStack(spacing: geo.size.width * 0.015) {
                                                Text(r == r.rounded() ? "\(Int(r))" : String(format: "%.1f", r))
                                                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.038))
                                                    .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: geo.size.width * 0.032))
                                                    .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, hPad)
                                    .padding(.vertical, geo.size.height * 0.015)
                                }
                                .background(Color("backgroundColorAccent").opacity(0.2).clipShape(RoundedRectangle(cornerRadius: cardCorner)))
                            }
                        }
                        .padding(.horizontal, hPad)
                    }
                }
                .padding(.top, geo.size.height * 0.03)
                .padding(.bottom, geo.size.height * 0.05)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.refreshRatings() } }
        }
    }
}
