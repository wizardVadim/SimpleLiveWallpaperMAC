//
//  HomeView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct HomeView: View {
    @Binding var selectedScreen: NSScreen?
    @EnvironmentObject var screenManager: ScreenManager
    @EnvironmentObject var wallpaperManager: WallpaperManager
    var body: some View {
        ScreensView(selectedScreen: $selectedScreen)
    }
}

struct ScreensView: View {
    @Binding var selectedScreen: NSScreen?
    @EnvironmentObject var screenManager: ScreenManager
    @EnvironmentObject var wallpaperManager: WallpaperManager
    
    var body: some View {
        if let selectedScreen = selectedScreen {
            VStack(alignment: .leading, spacing: 5) {
                Text("screens_settings")
                    .font(.largeTitle)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                let screens = screenManager.screens
                
                if !screens.isEmpty {

                    ScrollView {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                                ScreensRow(
                                    screen: screen,
                                    selectedScreen: $selectedScreen
                                )
                            }
                        }
                        .padding()
                    }

                } else {
                    Text("empty_message_home_screens")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct ScreensRow: View {
    let screen: NSScreen
    @EnvironmentObject var screenManager: ScreenManager
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    @State private var isHovered = false
    @State private var showTooltip = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        let colorToShadow = (colorScheme == .dark) ? STYLE_COLOR_L.opacity(0.8) : STYLE_COLOR_D
        
        if let localSelectedScreen = selectedScreen {
            
            VStack(alignment: .leading) {
                // Изображение
                AsyncImage(url: wallpaperManager.getScreenImage(screen: screen)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 160, height: 90)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 90)
                            .cornerRadius(5)

                    case .failure:
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 90)

                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                Text(screen.localizedName)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .center)
                
            }
            .frame(width: 240, height: 155)
            .padding(8) // Добавим немного отступа
            .animation(.easeInOut(duration: 0.2), value: showTooltip)
            .onTapGesture {
                selectedScreen = screen
            }
            .shadow(
                color: selectedScreen == screen
                    ? colorToShadow
                    : .clear,
                radius: selectedScreen == screen ? 8 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: selectedScreen)
        }
    }
}
