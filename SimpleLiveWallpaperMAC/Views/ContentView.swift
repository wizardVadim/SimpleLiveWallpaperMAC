//
//  ContentView.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 13.01.2026.
//

import SwiftUI
internal import UniformTypeIdentifiers

var STYLE_COLOR_D: Color = Color(
    red: 255 / 255.0,
    green: 177 / 255.0,
    blue: 250 / 255.0,
    opacity: 1
)

var STYLE_COLOR_L: Color = Color(
    red: 255 / 255.0,
    green: 199 / 255.0,
    blue: 251 / 255.0,
    opacity: 1
)

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
            DetailView(selection: selection, selectedScreen: $selectedScreen, showingFilePicker: $showingFilePicker)
            
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
                print("📁 file: \(url.path)")
                
                // Передаем файл в менеджер
                // Теперь он сам скопирует его в sandbox
                wallpaperManager.addWallpaper(url: url)
            }
        case .failure(let error):
            print("❌ error choosing file: \(error)")
        }
    }
}

struct DetailView: View {
    let selection: AppPage?
    @Binding var selectedScreen: NSScreen?
    @Binding var showingFilePicker: Bool

    var body: some View {
        TitleView()
        Group {
            switch selection {
            case .home:
                HomeView(selectedScreen: $selectedScreen)
            case .wallpapers:
                WallpapersView(selectedScreen: $selectedScreen, showingFilePicker: $showingFilePicker)
            case .about:
                AboutView()
            case .queue:
                QueueView(selectedScreen: $selectedScreen)
            default:
                Text("choose_a_page")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
