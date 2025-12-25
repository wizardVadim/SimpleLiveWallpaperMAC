//
//  ContentView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.12.2025.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    // Получаем WallpaperManager из окружения
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @EnvironmentObject var screenManager: ScreenManager
    @State private var showingFilePicker = false
    @State private var selectedScreen: NSScreen? = NSScreen.main
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            Text("🎬 Simple Live Wallpaper")
                .font(.title)
                .fontWeight(.bold)
            
            // Status, activation, info
            ControlPanelView(selectedScreen: $selectedScreen)
            
            ScreensView(selectedScreen: $selectedScreen)
            
            // TODO: Add func to use wallpapers by queue and view selected wallpapers
            // CurrentWallpapersView()
            
            // Add new wallpaper to available
            AddingPanelView(showingFilePicker: $showingFilePicker)
            
            // All available wallpapers
            AvailableWallpapersView(selectedScreen: $selectedScreen)
            
            Spacer()
        }
        .padding()
        .onAppear {
            wallpaperManager.loadWallpapers()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [
                .movie,
                .mpeg4Movie,
                .quickTimeMovie,
                .video,
                .audiovisualContent
            ],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                print("📁 Выбран файл: \(url.path)")
                
                // Передаем файл в менеджер
                // Теперь он сам скопирует его в sandbox
                wallpaperManager.addWallpaper(url: url)
            }
        case .failure(let error):
            print("❌ Ошибка выбора файла: \(error)")
        }
    }
}

struct AvailableWallpapersView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    
    var body: some View {
        if let selectedScreen = selectedScreen {
            VStack(alignment: .leading, spacing: 5) {
                Text("Available Wallpapers")
                    .font(.headline)
                    .padding(.horizontal)
                
                if wallpaperManager.availableWallpapers.isEmpty {
                    Text("Add your first video")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(wallpaperManager.availableWallpapers) { wallpaper in
                            AvailableWallpaperRow(wallpaper: wallpaper, selectedScreen: $selectedScreen)
                        }
                    }
                    .frame(height: 150)
                }
            }
        }
    }
}

struct AvailableWallpaperRow: View {
    let wallpaper: Wallpaper
    @EnvironmentObject var manager: WallpaperManager
    @Binding var selectedScreen: NSScreen?
    
    var isSelected: Bool {
        guard let selectedScreen = selectedScreen else { return false }
        print("")
        return manager.currentWallpapers[selectedScreen]?.contains(where: { $0.id == wallpaper.id }) ?? false
    }
    
    var body: some View {
        
        if let selectedScreen = selectedScreen {
            
            HStack {
                // Иконка
                Image(systemName: "photo")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                // Информация
                VStack(alignment: .leading) {
                    Text(wallpaper.title)
                        .font(.body)
                    
                    Text(wallpaper.url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                // Кнопки
                if isSelected {
                    Button("Убрать") {
                        manager.removeFromCurrent(wallpaper, screen: selectedScreen)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                } else {
                    Button("Выбрать") {
                        manager.selectWallpaper(wallpaper, screen: selectedScreen)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Кнопки
                Button(action: {
                    manager.removeFromAvailable(wallpaper)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
            
        }
    }
}

struct AddingPanelView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var showingFilePicker: Bool
    
    var body: some View {
        Button(action: { showingFilePicker = true }) {
                Label("Добавить обои", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
                    
    }
}

struct ControlPanelView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    
    @Binding var selectedScreen: NSScreen?
    
    let timeOptions = [0, 30, 60, 90, 180, 300, 600, 6000]
    
    var body: some View {
        
        VStack(spacing: 10) {
            
            // Status
            HStack {
                
                Circle()
                    .fill(wallpaperManager.isPlaying ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(wallpaperManager.isPlaying ? "Играет" : "Остановлено")
                    .foregroundColor(wallpaperManager.isPlaying ? .green : .red)
            }
            
            // Control buttons
            HStack(spacing: 20) {
                if let selectedScreen = selectedScreen {
                    Button(action: {
                        if wallpaperManager.isPlaying {
                            wallpaperManager.stop()
                        } else {
                            wallpaperManager.start()
                        }
                    }) {
                        Label(
                            wallpaperManager.isPlaying ? "Остановить" : "Включить",
                            systemImage: wallpaperManager.isPlaying ? "stop.fill" : "play.fill"
                        )
                        .frame(width: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(wallpaperManager.currentWallpapers[selectedScreen]?.isEmpty ?? true)
                }
            }
            
            HStack {
                Text("Время для смены обоев (сек):")
                Picker("Время", selection: $wallpaperManager.timeToChange) {
                    ForEach(timeOptions, id: \.self) { time in
                        Text("\(time) сек").tag(time)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                .onChange(of: wallpaperManager.timeToChange) { oldValue, newValue in
                    if wallpaperManager.isPlaying {
                        wallpaperManager.stop()
                        wallpaperManager.start()
                    }
                    wallpaperManager.saveTimeToChange()
                }
            }
            .padding(.top)
            
            
            // Wallpaper info
            if let selectedScreen = selectedScreen, let current = wallpaperManager.currentWallpapers[selectedScreen]?.first {
                Text("Текущие обои: \(current.title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        
    }
}

struct ScreensView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @EnvironmentObject var screenManager: ScreenManager
    
    @Binding var selectedScreen: NSScreen?
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Выберите экран")
                .font(.headline)
            
            // Выбор экрана
            Picker("Экраны", selection: $selectedScreen) {
                ForEach(screenManager.screens, id: \.self) { screen in
                    Text(screen.localizedName)
                        .tag(screen as NSScreen?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            if let selectedScreen = selectedScreen {
                Text("Выбран экран: \(selectedScreen.localizedName)")
                    .font(.subheadline)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}

// Предпросмотр для SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WallpaperManager())  // Для превью
    }
}
