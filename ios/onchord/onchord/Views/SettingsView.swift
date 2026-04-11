//
//  SettingsView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        List {
            Section {
                Button("Log out") {
                    authManager.logout()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    SettingsView()
}
