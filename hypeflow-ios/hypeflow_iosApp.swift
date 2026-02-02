//
//  hypeflow_iosApp.swift
//  hypeflow-ios
//
//  Created by Denys on 2/1/26.
//

import SwiftUI
import SwiftData

@main
struct hypeflow_iosApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FavoriteTrend.self, SavedSearch.self])
    }
}
