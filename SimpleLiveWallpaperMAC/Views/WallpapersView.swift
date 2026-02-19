//
//  WallpapersView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//
import SwiftUI

struct WallpapersView: View {
    @Binding var selectedScreen: NSScreen?
    @Binding var showingFilePicker: Bool
    @EnvironmentObject var wallpaperManager: WallpaperManager
    
    @State var selectedWallpaper: Wallpaper?
    
    var body: some View {
        VStack() {
            
            MyWallpapersView(selectedScreen: $selectedScreen, selectedWallpaper: $selectedWallpaper)
                .frame(alignment: .topLeading)
                .frame( maxHeight: .infinity, alignment: .top, )
        
            HStack() {
                Button(action: { showingFilePicker = true }) {
                        Label {
                            Text("upload")
                        } icon: {
                            EmptyView()
                        }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .tint(STYLE_COLOR_L)
                    .frame(width: 200)
                
                Button(action: { if let selectedWallpaper = selectedWallpaper, let selectedScreen = selectedScreen {wallpaperManager.removeFromAvailable(selectedWallpaper)} }) {
                            Label {
                                Text("remove")
                            } icon: {
                                EmptyView()
                            }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 20)
                    .tint(STYLE_COLOR_L)
                    .frame(width: 300)
                
                Button(action: { if let selectedWallpaper = selectedWallpaper, let selectedScreen = selectedScreen {wallpaperManager.selectWallpaper(selectedWallpaper, screen: selectedScreen)} }) {
                            Label {
                                Text("to_queue")
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

struct MyWallpapersView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    @Binding var selectedWallpaper: Wallpaper?
    
    var body: some View {
        if let selectedScreen = selectedScreen {
            VStack(alignment: .leading, spacing: 5) {
                Text("available_wallpapers")
                    .font(.largeTitle)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if wallpaperManager.availableWallpapers.isEmpty {
                    Text("empty_message_wallpapers")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    // Используем ScrollView для горизонтального прокручивания
                    ScrollView {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(wallpaperManager.availableWallpapers) { wallpaper in
                                MyWallpapersRow(
                                    wallpaper: wallpaper,
                                    selectedScreen: $selectedScreen,
                                    selectedWallpaper: $selectedWallpaper
                                )
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
    @Binding var selectedWallpaper: Wallpaper?
    @State private var isHovered = false
    @State private var showTooltip = false
    @Environment(\.colorScheme) var colorScheme
    
    var isSelected: Bool {
        guard let selectedScreen = selectedScreen else { return false }
        print("")
        return manager.currentWallpapers[selectedScreen]?.contains(where: { $0.id == wallpaper.id }) ?? false
    }
    
    var body: some View {
        
        let colorToShadow = (colorScheme == .dark) ? STYLE_COLOR_L.opacity(0.8) : STYLE_COLOR_D
        
        if let selectedScreen = selectedScreen {
                        
            VStack(alignment: .leading) {
                // Изображение
                AsyncImage(url: wallpaper.imageURL!) { phase in
                    switch phase {
                    case .empty:
                        ProgressView() // пока грузится
                            .frame(width: 160, height: 90)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 90)
                            .cornerRadius(5)

                    case .failure:
                        Image(systemName: "photo.fill") // если ошибка
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 90)

                    @unknown default:
                        EmptyView()
                    }
                }
                .onHover { hovering in
                    isHovered = hovering
                    showTooltip = hovering
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                
                Text(wallpaper.title)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if showTooltip {
                    Text(wallpaper.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(5)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .offset(y: 10)
                        .transition(.opacity) 
                }
            }
            .frame(width: 240, height: 155)
            .padding(8) // Добавим немного отступа
            .animation(.easeInOut(duration: 0.2), value: showTooltip)
            .onTapGesture {
                selectedWallpaper = wallpaper
            }
            .shadow(
                color: selectedWallpaper?.id == wallpaper.id
                    ? colorToShadow
                    : .clear,
                radius: selectedWallpaper?.id == wallpaper.id ? 8 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: selectedWallpaper?.id)
        }
    }
}
