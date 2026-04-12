//
//  ScrollableRatedSongsView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct ScrollableRatedSongsView: View {
    let songs: [RatedSong]
    let geo: GeometryProxy
    private var recentSongs: [RatedSong] {
        Array(songs.prefix(10))
    }

    var body: some View {
        VStack {
            HStack {
                Text("RECENT SONG RATINGS")
                    .font(.custom("OpenSans-Bold", size: geo.size.width * 0.04))
                    .foregroundStyle(Color("greenLight"))
                    .padding()
                Spacer()
            }
            if (recentSongs.isEmpty) {
                Text("No songs rated yet")
                    .font(.custom("OpenSans-Regular", size: geo.size.width * 0.03))
                    .foregroundStyle(Color("greenLight").opacity(0.5))
                    .padding(.bottom)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(recentSongs) { song in
                            SongCardView(song: song, geo: geo)
                        }
                    }
                    .padding(geo.size.width * 0.01)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color("backgroundColorAccent").cornerRadius(20).opacity(0.5))
    }
}
