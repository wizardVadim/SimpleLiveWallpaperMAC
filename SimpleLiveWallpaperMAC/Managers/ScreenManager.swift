//
//  ScreenManager.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 23.12.2025.
//
import SwiftUI
import Cocoa
import Combine

class ScreenManager: ObservableObject {
    
    @Published var screens: [NSScreen] = []
    
    init() {
        getScreens()
    }
    
    private func getScreens() {
        screens.append(contentsOf: NSScreen.screens)
    }
    
}
