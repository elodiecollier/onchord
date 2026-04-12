//
//  SongDetailView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct SongDetailView: View {
    @State private var viewModel: SongDetailViewModel

    init(track: TrackResult) {
        _viewModel = State(initialValue: SongDetailViewModel(track: track))
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
                        if viewModel.rating > 0 {
                            HStack(spacing: geo.size.width * 0.015) {
                                Text("RATED")
                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.03))
                                    .foregroundStyle(Color("greenLight"))
                                Image(systemName: "checkmark")
                                    .font(.system(size: geo.size.width * 0.028, weight: .semibold))
                                    .foregroundStyle(Color("greenLight"))
                            }
                            .padding(.horizontal, geo.size.width * 0.03)
                            .padding(.vertical, geo.size.height * 0.008)
                            .overlay {
                                RoundedRectangle(cornerRadius: geo.size.width * 0.03)
                                    .strokeBorder(Color("greenLight"), lineWidth: geo.size.width * 0.004)
                            }
                        } else {
                            Text("NOT RATED")
                                .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.03))
                                .foregroundStyle(Color("blueLight"))
                                .padding(.horizontal, geo.size.width * 0.03)
                                .padding(.vertical, geo.size.height * 0.008)
                                .overlay {
                                    RoundedRectangle(cornerRadius: geo.size.width * 0.03)
                                        .strokeBorder(Color("blueLight"), lineWidth: geo.size.width * 0.004)
                                }
                        }
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
                            AsyncImage(url: viewModel.track.largeImageUrl ?? viewModel.track.imageUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
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
                                    .strokeBorder(Color("greenLight"), lineWidth: geo.size.width * 0.012)
                            }
                            .shadow(radius: 8)

                            VStack(spacing: geo.size.height * 0.008) {
                                Text(viewModel.track.name)
                                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.055))
                                    .foregroundStyle(Color("greenLight"))
                                    .multilineTextAlignment(.center)

                                Text(viewModel.track.artistName)
                                    .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                    .foregroundStyle(Color("greenLight"))

                                if !viewModel.track.albumName.isEmpty {
                                    Text(viewModel.track.albumName)
                                        .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                        .foregroundStyle(Color("greenLight").opacity(0.7))
                                }
                            }
                            .padding(.horizontal, hPad)
                            .padding(.vertical, geo.size.height * 0.02)
                        }
                    }
                    .padding(.horizontal, hPad)

                    VStack(spacing: geo.size.height * 0.012) {
                        Text("Your Rating")
                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.045))
                            .foregroundStyle(Color("greenLight"))

                        StarRatingView(rating: $viewModel.rating)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.vertical, geo.size.height * 0.02)
                    .frame(maxWidth: .infinity)
                    .background(Color("backgroundColorAccent").opacity(0.2).clipShape(RoundedRectangle(cornerRadius: cardCorner)))
                    .padding(.horizontal, hPad)

                    VStack(alignment: .leading, spacing: geo.size.height * 0.015) {
                        Text("FRIEND RATINGS")
                            .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                            .foregroundStyle(Color("blueLight"))

                        if viewModel.friendRatings.isEmpty {
                            Text("No friends have rated this song yet")
                                .font(.custom("OpenSans-Regular", size: geo.size.width * 0.035))
                                .foregroundStyle(Color("blueLight").opacity(0.5))
                        } else {
                            ForEach(viewModel.friendRatings) { friend in
                                NavigationLink(value: UserResult(id: friend.id, displayName: friend.displayName, profileImageUrl: friend.profileImageUrl)) {
                                    HStack(spacing: geo.size.width * 0.03) {
                                        AsyncImage(url: friend.profileImageUrl) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            default:
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundStyle(Color("blueLight").opacity(0.6))
                                            }
                                        }
                                        .frame(width: geo.size.width * 0.1, height: geo.size.width * 0.1)
                                        .clipShape(Circle())

                                        Text(friend.displayName)
                                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.038))
                                            .foregroundStyle(Color("blueLight"))
                                            .lineLimit(1)

                                        Spacer()

                                        HStack(spacing: geo.size.width * 0.015) {
                                            Text(friend.rating == friend.rating.rounded() ? "\(Int(friend.rating))" : String(format: "%.1f", friend.rating))
                                                .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                                                .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                            Image(systemName: "star.fill")
                                                .font(.system(size: geo.size.width * 0.035))
                                                .foregroundStyle(BlueGreenDiagonalGradient.gradient)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.vertical, geo.size.height * 0.02)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("backgroundColorAccent").opacity(0.2).clipShape(RoundedRectangle(cornerRadius: cardCorner)))
                    .padding(.horizontal, hPad)

                    if !viewModel.track.albumName.isEmpty, let albumId = viewModel.track.albumId {
                        let album = AlbumResult(
                            id: albumId,
                            name: viewModel.track.albumName,
                            artistName: viewModel.track.artistName,
                            albumType: viewModel.track.albumType,
                            imageUrl: viewModel.track.largeImageUrl ?? viewModel.track.imageUrl
                        )
                        VStack(alignment: .leading, spacing: geo.size.height * 0.015) {
                            Text("EXPLORE THE ALBUM")
                                .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                                .foregroundStyle(Color("blueLight"))

                            NavigationLink(value: album) {
                                HStack(spacing: geo.size.width * 0.04) {
                                    AsyncImage(url: album.imageUrl) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        default:
                                            RoundedRectangle(cornerRadius: geo.size.width * 0.02)
                                                .fill(Color.gray.opacity(0.2))
                                                .overlay {
                                                    Image(systemName: "music.note")
                                                        .foregroundStyle(Color("blueLight").opacity(0.5))
                                                }
                                        }
                                    }
                                    .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                                    .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.02))

                                    VStack(alignment: .leading, spacing: geo.size.height * 0.005) {
                                        Text(album.name)
                                            .font(.custom("OpenSans-SemiBold", size: geo.size.width * 0.04))
                                            .foregroundStyle(Color("blueLight"))
                                            .lineLimit(1)
                                        Text(album.artistName)
                                            .font(.custom("OpenSans-Regular", size: geo.size.width * 0.032))
                                            .foregroundStyle(Color("blueLight").opacity(0.7))
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: geo.size.width * 0.04))
                                        .foregroundStyle(Color("blueLight").opacity(0.6))
                                }
                            }
                        }
                        .padding(.horizontal, hPad)
                        .padding(.vertical, geo.size.height * 0.02)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("backgroundColorAccent").opacity(0.2).clipShape(RoundedRectangle(cornerRadius: cardCorner)))
                        .padding(.horizontal, hPad)
                    }

                    if viewModel.isSaving {
                        ProgressView()
                    }
                }
                .padding(.top, geo.size.height * 0.03)
                .padding(.bottom, geo.size.height * 0.05)
            }
        }
        .navigationDestination(for: UserResult.self) { user in
            UserProfileView(user: user)
        }

        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadRating() }
        .onChange(of: viewModel.rating) { _, newValue in
            Task { await viewModel.saveRating(newValue) }
        }
        }
    }
}
