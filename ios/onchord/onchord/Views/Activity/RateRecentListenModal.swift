//
//  RateRecentListenModal.swift
//  onchord
//
//  Created by Elodie Collier on 4/13/26.
//

import SwiftUI

struct RateRecentListenModal: View {
    let track: TrackResult
    let isActive: Bool
    @Binding var rating: Double
    let onSave: () async -> Void
    let geo: GeometryProxy
    let cardWidth: CGFloat
    private var imageSize: CGFloat { cardWidth * 0.40 }
    private var imageCorner: CGFloat { geo.size.width * 0.04 }
    private var hPad: CGFloat { cardWidth * 0.07 }
    private var cardCorner: CGFloat { geo.size.width * 0.045 }

    var body: some View {
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

            StarRatingView(rating: $rating)
                .scaleEffect(0.78)
                .frame(height: 30)

            if isActive && rating > 0 {
                Button {
                    Task { await onSave() }
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
    }
}
