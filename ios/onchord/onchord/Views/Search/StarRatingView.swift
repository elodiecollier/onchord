//
//  StarRatingView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImage(for: star))
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        let full = Double(star)
                        let half = full - 0.5
                        if rating == full {
                            rating = half       // filled → half
                        } else if rating == half {
                            rating = 0           // half → clear
                        } else {
                            rating = full        // anything else → filled
                        }
                    }
            }
        }
    }

    private func starImage(for position: Int) -> String {
        if rating >= Double(position) {
            return "star.fill"
        } else if rating >= Double(position) - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
