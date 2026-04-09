//
//  SearchArtworkView.swift
//  onchord
//
//  Created by Elodie Collier on 4/9/26.
//

import SwiftUI

struct SearchArtworkView: View {
    let url: URL?
    let isCircle: Bool

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: isCircle ? "person.fill" : "music.note")
                            .foregroundColor(.gray)
                    }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 6)))
    }
}
