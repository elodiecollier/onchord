//
//  GradientBackgroundMain.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct GradientBackgroundMain: View {
    var body: some View {
        LinearGradient(
            colors: [Color("backgroundColorPrimary"), Color("backgroundColorSecondary")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    GradientBackgroundMain()
}
