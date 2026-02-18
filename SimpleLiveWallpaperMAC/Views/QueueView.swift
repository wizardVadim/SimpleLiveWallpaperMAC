//
//  QueueView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 19.02.2026.
//
import SwiftUI

struct QueueView: View {
    @Binding var selectedScreen: NSScreen?
    @EnvironmentObject var wallpaperManager: WallpaperManager
    
    @State var selectedWallpaper: Wallpaper?
    
    var body: some View {
        VStack() {
            
            CurrentWallpapersView(selectedScreen: $selectedScreen, selectedWallpaper: $selectedWallpaper)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        
            HStack() {
                
                Button(action: { if let selectedWallpaper = selectedWallpaper, let selectedScreen = selectedScreen {wallpaperManager.removeFromCurrent(selectedWallpaper, screen: selectedScreen)} }) {
                            Label {
                                Text("Убрать из очереди")
                            } icon: {
                                EmptyView()
                            }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .tint(STYLE_COLOR_L)
                    .frame(width: 300)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .bottom)
            
        }
        .frame( maxHeight: .infinity, alignment: .top, )
        
    }
}

struct CurrentWallpapersView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    @Binding var selectedWallpaper: Wallpaper?
    
    var body: some View {
        if let selectedScreen = selectedScreen {
            VStack(alignment: .leading, spacing: 5) {
                Text("Текущие обои")
                    .font(.largeTitle)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if let wallpapers = wallpaperManager.currentWallpapers[selectedScreen],
                   !wallpapers.isEmpty {

                    ScrollView {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(wallpapers) { wallpaper in
                                MyWallpapersRow(
                                    wallpaper: wallpaper,
                                    selectedScreen: $selectedScreen,
                                    selectedWallpaper: $selectedWallpaper
                                )
                            }
                        }
                        .padding()
                    }

                } else {
                    Text("Добавьте обои на вкладке 'Мои обои'")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}
