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
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    private func getScreens() {
        screens = NSScreen.screens
    }
    
    @objc private func screenChanged(notification: Notification) {
        getScreens()
        print("Screens updated: \(screens.count) screens")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
