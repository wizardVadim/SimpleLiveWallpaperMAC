//
//  ContentView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    // Получаем WallpaperManager из окружения
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @EnvironmentObject var screenManager: ScreenManager
    @State private var showingFilePicker = false
    @State private var selectedScreen: NSScreen? = NSScreen.main
    @State private var selection: AppPage? = .home
    
    var body: some View {
            
        NavigationSplitView {
            SidebarView(selection: $selection)
                .frame(maxWidth: 250)
        } detail: {
            DetailView(selection: selection, selectedScreen: $selectedScreen)
            Button("Очистить все настройки") {
                wallpaperManager.reboot()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .padding()
        }
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

struct DetailView: View {
    let selection: AppPage?
    @Binding var selectedScreen: NSScreen?

    var body: some View {
        Group {
            switch selection {
            case .home:
                HomeView()
            case .wallpapers:
                WallpapersView(selectedScreen: $selectedScreen)
            case .about:
                AboutView()
            default:
                Text("Выберите раздел")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Предпросмотр для SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WallpaperManager())  // Для превью
            .environmentObject(ScreenManager())
            .frame(width: 1200, height: 800)
    }
}
