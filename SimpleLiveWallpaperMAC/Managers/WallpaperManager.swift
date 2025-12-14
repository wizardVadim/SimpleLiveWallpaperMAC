// Managers/WallpaperManager.swift
import SwiftUI
import Cocoa
import Combine

class WallpaperManager: ObservableObject {
    @Published var isPlaying = false
    private var player: VideoPlayer?
    private var containerWindow: NSWindow?

    @Published var availableWallpapers: [Wallpaper] = []
    @Published var currentWallpapers: [Wallpaper] = []
    
    private let wallpapersDirectory: URL
        
    init() {
        let fileManager = FileManager.default
        
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        wallpapersDirectory = appSupport.appendingPathComponent("SimpleLiveWallpaper", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: wallpapersDirectory, withIntermediateDirectories: true)
            print("📁 Wallpapers directory: \(wallpapersDirectory.path)")
        } catch {
            print("❌ Error creating a directory: \(error)")
        }
    }
        
    private func copyToSandbox(url: URL) throws -> URL {
        let fileName = url.lastPathComponent
        
        // Unique file name
        let uniqueName = "\(UUID().uuidString)_\(fileName)"
        let destinationURL = wallpapersDirectory.appendingPathComponent(uniqueName)
        
        print("📋 Is copying:")
        print("From: \(url.path)")
        print("To: \(destinationURL.path)")
        
        // Копируем файл
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // use right rules
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: destinationURL.path
        )
        
        return destinationURL
    }
    
    func saveWallpapers() {
        do {
            let data = try JSONEncoder().encode(availableWallpapers)
            UserDefaults.standard.set(data, forKey: "savedWallpapers")
            print("Wallpaper's saved count: \(availableWallpapers.count)")
        } catch {
            print("Save error!")
        }
    }
    
    func loadWallpapers() {
        
        guard let data = UserDefaults.standard.data(forKey: "savedWallpapers") else {
            print("ℹ️ No saved wallpapers")
            return
        }
        
        do {
            availableWallpapers = try JSONDecoder().decode([Wallpaper].self, from: data)
            print("📥 Loaded wallpapers count: \(availableWallpapers.count)")
            
            var validWallpapers: [Wallpaper] = []
            
            for wallpaper in availableWallpapers {
                let path = wallpaper.url.path
                
                if FileManager.default.fileExists(atPath: path) {
                    let isReadable = FileManager.default.isReadableFile(atPath: path)
                    print("✅ File found: \(wallpaper.title) - readable: \(isReadable)")
                    
                    if isReadable {
                        validWallpapers.append(wallpaper)
                    }
                } else {
                    print("❌ File is not found: \(wallpaper.title)")
                }
            }
            
            if validWallpapers.count != availableWallpapers.count {
                availableWallpapers = validWallpapers
                saveWallpapers()
                print("🔄 Wallpapers updated. Total count: \(availableWallpapers.count)")
            }
            
        } catch {
            print("❌ Loading wallpapers failed: \(error)")
        }
    }
    
    func addWallpaper(url: URL) {
        
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Could'nt access the file")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            // Копируем файл в sandbox приложения
            let sandboxURL = try copyToSandbox(url: url)
            
            // Проверяем, что файл доступен
            let isReadable = FileManager.default.isReadableFile(atPath: sandboxURL.path)
            print("✅ File is copied to sandbox")
            print("Readable: \(isReadable)")
            print("Size: \(try FileManager.default.attributesOfItem(atPath: sandboxURL.path)[.size] as? Int64 ?? 0) байт")
            
            // Создаем Wallpaper с новым URL (внутри sandbox)
            var wallpaper = Wallpaper(url: sandboxURL)
            wallpaper.fileName = url.lastPathComponent  // Сохраняем оригинальное имя
            
            // Добавляем в список
            availableWallpapers.append(wallpaper)
            saveWallpapers()
            
            print("✅ Wallpaper is added: \(wallpaper.title)")
            
        } catch {
            print("❌ adding wallpaper error: \(error.localizedDescription)")
        }
    }
    
    func start(playScreenSaver: Bool = false) {
        
        startOnDesktop()
        
        print("playScreenSaver: \(playScreenSaver)")
        if playScreenSaver {
            startOnScreenSaver()
        }
        
    }
    
    func startOnDesktop() {
        guard !isPlaying, let wallpaper = currentWallpapers.first else { return }
        
        guard let screen = NSScreen.main else { return }
        
        let window = NSWindow(contentRect: screen.frame,
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.stationary, .canJoinAllSpaces, .ignoresCycle]
        
        let view = VideoPlayer(frame: screen.frame)
        view.videoURL = wallpaper.url
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        
        containerWindow = window
        player = view
        isPlaying = true
    }
    
    func startOnScreenSaver() {
        print("playScreenSaver")
        guard let wallpaper = currentWallpapers.first else { return }
            
        LockScreenUtil.setLockScreen(fromVideo: wallpaper.url)
    }
    
    func stop() {
        guard let player = player else { return }

        player.removeFromSuperviewSafely()
        player.stopVideo()

        if let window = containerWindow {
            window.orderOut(nil)
            containerWindow = nil
        }

        self.player = nil
        isPlaying = false
    }
    
    func selectWallpaper(_ wallpaper: Wallpaper) {
        currentWallpapers.insert(wallpaper, at: 0)
        
        if isPlaying {
            stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.start()
            }
        }
        
        print("✅ Selected wallpaper: \(wallpaper.title)")
    }
    
    func removeFromAvailable(_ wallpaper: Wallpaper) {
        availableWallpapers.removeAll { $0.id == wallpaper.id }
        saveWallpapers()
        print("🗑 Removed from available: \(wallpaper.title)")
    }
}
