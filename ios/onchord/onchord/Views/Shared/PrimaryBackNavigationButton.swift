//
//  PrimaryBackNavigationButton.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct PrimaryBackNavigationButton: View {
    @Environment(\.dismiss) private var dismiss
    let geo: GeometryProxy
    
    var body: some View {
        Button (action: {
            dismiss()
        }) {
            Image(systemName: "arrow.backward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width * 0.045)
                .foregroundStyle(Color("greenLight"))
        }
    }
}
