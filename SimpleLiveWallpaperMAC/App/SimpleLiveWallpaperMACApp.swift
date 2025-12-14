//
//  SimpleLiveWallpaperMACApp.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.12.2025.
//

import SwiftUI

@main
struct SimpleLiveWallpaperMACApp: App {
    @StateObject private var wallpaperManager = WallpaperManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wallpaperManager)
                .frame(width: 300, height: 500)
                .onDisappear {
                    wallpaperManager.stop()
                }
                .onAppear {
                    if !wallpaperManager.currentWallpapers.isEmpty {
                        wallpaperManager.start()
                    }
                }
        }
        .windowResizability(.automatic)
    }
}
