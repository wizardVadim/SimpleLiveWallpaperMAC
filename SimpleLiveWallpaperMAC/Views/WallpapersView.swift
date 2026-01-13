//
//  WallpapersView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct WallpapersView: View {
    @Binding var selectedScreen: NSScreen?
    var body: some View {
        TitleView()
        VStack() {
            MyWallpapersView(selectedScreen: $selectedScreen)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct MyWallpapersView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    
    var body: some View {
        if let selectedScreen = selectedScreen {
            VStack(alignment: .leading, spacing: 5) {
                Text("Загруженные обои")
                    .font(.largeTitle)
                    .padding(.horizontal)
                
                if wallpaperManager.availableWallpapers.isEmpty {
                    Text("Add your first video")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    // Используем ScrollView для горизонтального прокручивания
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) { // Расстояние между обоями
                            ForEach(wallpaperManager.availableWallpapers) { wallpaper in
                                MyWallpapersRow(wallpaper: wallpaper, selectedScreen: $selectedScreen)
                                    .frame(width: 240, height: 135)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}


struct MyWallpapersRow: View {
    let wallpaper: Wallpaper
    @EnvironmentObject var manager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    @State private var isHovered = false
    @State private var showTooltip = false
    
    var isSelected: Bool {
        guard let selectedScreen = selectedScreen else { return false }
        print("")
        return manager.currentWallpapers[selectedScreen]?.contains(where: { $0.id == wallpaper.id }) ?? false
    }
    
    var body: some View {
        
        if let selectedScreen = selectedScreen {
                        
            VStack(alignment: .leading) {
                // Изображение
                Image(systemName: "photo.fill") // Просто пример, тут будет ваш фон
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 90)
                    .cornerRadius(5)
                    .onHover { hovering in
                        isHovered = hovering // Обновляем состояние наведения
                        showTooltip = hovering // Показываем подсказку при наведении
                    }
                
                Spacer()
                
                Text(wallpaper.title)
                    .font(.body)
                
                if showTooltip {
                    Text(wallpaper.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(5)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .offset(y: 10) // Можно настроить отступ от элемента
                        .transition(.opacity) // Плавное появление
                }
            }
            .padding(.vertical, 4) // Добавим немного отступа
            .animation(.easeInOut(duration: 0.2), value: showTooltip)
        }
    }
}
