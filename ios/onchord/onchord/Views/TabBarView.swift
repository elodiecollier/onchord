//
//  TabBarView.swift
//  onchord
//
//  Created by Elodie Collier on 4/11/26.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ActivityView()
            }
            .tabItem {
                Label("Activity", systemImage: "star.fill")
            }
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                MyProfileView()
            }
            .tabItem {
                Label("My Profile", systemImage: "person.circle")
            }
        }
    }
}

#Preview {
    TabBarView()
}
