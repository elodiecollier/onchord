//
//  BlueGreenDiagonalGradient.swift
//  onchord
//
//  Created by Elodie Collier on 4/12/26.
//

import SwiftUI

struct BlueGreenDiagonalGradient: View {
    static let gradient = LinearGradient(
        colors: [Color("blueLight"), Color("greenLight")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Self.gradient
    }
}

#Preview {
    BlueGreenDiagonalGradient()
}
