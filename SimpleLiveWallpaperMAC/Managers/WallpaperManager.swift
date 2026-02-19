// Managers/WallpaperManager.swift
import SwiftUI
import Cocoa
import Combine

class WallpaperManager: ObservableObject {
    @Published var isPlaying = false
    private var players: [NSScreen : VideoPlayer] = [:]
    private var containersWindow: [NSScreen : NSWindow] = [:]
    private var screenManager: ScreenManager?
    private var screensImages: [NSScreen: URL] = [:]
    
    private var MAX_AVAILABLE_WALLPAPERS: Int = 20
    private var MAX_CURRENT_WALLPAPERS: Int = 10

    @Published var availableWallpapers: [Wallpaper] = []
    @Published var currentWallpapers: [NSScreen : [Wallpaper]] = [:]
    private var currentWallpaperIndexes: [NSScreen : Int] = [:]
    
    @Published var timeToChange: Int = 0
    
    private var timer: Timer?
    
    private let wallpapersDirectory: URL
    private var screenSleepObserver: Any?
    private var screenWakeObserver: Any?
        
    init() {
        
        screenManager = ScreenManager()
        
        let fileManager = FileManager.default
        
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        wallpapersDirectory = appSupport.appendingPathComponent("SimpleLiveWallpaper", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: wallpapersDirectory, withIntermediateDirectories: true)
            print("📁 Wallpapers directory: \(wallpapersDirectory.path)")
        } catch {
            print("❌ Error creating a directory: \(error)")
        }
        
        loadWallpapers()
        loadTimeToChange()
        
        initCurrentWallpaperIndexes()
        
        completeScreensImages()
        setupPowerManagementObservers()
        
//        if !currentWallpapers.isEmpty {
//            start()
//        }
        
    }
    
    deinit {
       let notificationCenter = NSWorkspace.shared.notificationCenter
       
       if let screenSleepObserver = screenSleepObserver {
           notificationCenter.removeObserver(screenSleepObserver)
       }
       if let screenWakeObserver = screenWakeObserver {
           notificationCenter.removeObserver(screenWakeObserver)
       }
   }
    
    private func setupPowerManagementObservers() {
           // Наблюдатель за пробуждением системы от сна
           let notificationCenter = NSWorkspace.shared.notificationCenter
           
           // Когда экран просыпается
           screenWakeObserver = notificationCenter.addObserver(
               forName: NSWorkspace.screensDidWakeNotification,
               object: nil,
               queue: .main
           ) { [weak self] _ in
               print("Screen woke up")
               DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                   self?.stop()
                   self?.start()
               }
           }
           
           // Когда экран засыпает (на всякий случай)
           screenSleepObserver = notificationCenter.addObserver(
               forName: NSWorkspace.screensDidSleepNotification,
               object: nil,
               queue: .main
           ) { [weak self] _ in
               print("Screen is sleeping")
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                   self?.stop()
               }
           }
       }
    
    func getScreenImage(screen: NSScreen) -> URL? {
        var currentImage = screensImages[screen] ?? nil
        if currentImage == nil {
            if let path = Bundle.main.path(forResource: "images-no", ofType: "png") {
                currentImage = URL(fileURLWithPath: path)
                screensImages[screen] = currentImage
            }
        }
        return currentImage
    }
    
    private func completeScreensImages() {
        screensImages.removeAll()
        if let screens = screenManager?.screens {
           for screen in screens {
               if let imgUrl = getCurrentWallpaper(screen: screen)?.imageURL {
                   addScreenImage(screen: screen, url: imgUrl)
               }
           }
       }
    }
    
    private func addScreenImage(screen: NSScreen, url: URL) {
        screensImages[screen] = url
    }
    
    private func initCurrentWallpaperIndexes() {
        for (screen, _) in currentWallpapers {
            currentWallpaperIndexes[screen] = 0
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
    
    func saveTimeToChange() {
        do {
            let data = try JSONEncoder().encode(timeToChange)
            UserDefaults.standard.set(data, forKey: "timeToChange")
            print("Time to change saved: \(timeToChange)")
        } catch {
            print("Save error!")
        }
    }
    
    func loadTimeToChange() {
        guard let data = UserDefaults.standard.data(forKey: "timeToChange") else {
            print("ℹ️ No time to change")
            return
        }
        
        do {
            timeToChange = try JSONDecoder().decode(Int.self, from: data)
            print("📥 Time to change loaded: \(timeToChange)")
            
        } catch {
            print("❌ Loading time to change param failed: \(error)")
        }
    }
    
    func saveWallpapers() {
        
        saveAvailableWallpapers()
        saveCurrentWallpapers()
    }
    
    func loadWallpapers() {
        
        loadAvailableWallpapers()
        loadCurrentWallpapers()
        
    }
    
    func addWallpaper(url: URL) {
        
        if availableWallpapers.count >= MAX_AVAILABLE_WALLPAPERS {
            print("Too many wallpapers")
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Could'nt access the file")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let sandboxURL = try copyToSandbox(url: url)
            
            let isReadable = FileManager.default.isReadableFile(atPath: sandboxURL.path)
            print("✅ File is copied to sandbox")
            print("Readable: \(isReadable)")
            print("Size: \(try FileManager.default.attributesOfItem(atPath: sandboxURL.path)[.size] as? Int64 ?? 0) байт")
            
            var wallpaper = Wallpaper(url: sandboxURL)
            wallpaper.fileName = url.lastPathComponent
            
            availableWallpapers.append(wallpaper)
            saveWallpapers()
            
            print("✅ Wallpaper is added: \(wallpaper.title)")
            
        } catch {
            print("❌ adding wallpaper error: \(error.localizedDescription)")
        }
    }
    
    func start() {
        
        if (timeToChange != 0) {
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(timeToChange), target: self, selector: #selector(playWallpaper), userInfo: nil, repeats: true)
        }
        playWallpaper(isFirstStart: true)
        
    }
    
    func stop() {
        
        timer?.invalidate()
        timer = nil
        stopPlaying()
    }
    
    private func stopPlaying() {
        if isPlaying {
            let screens = screenManager?.screens
            
            for screen in screens ?? [] {
                stopPlayingScreen(screen: screen)
            }
            
        }
        
        isPlaying = false
    }
    
    private func stopPlayingScreen(screen: NSScreen) {
        guard let player = players[screen] else { return }

        player.removeFromSuperviewSafely()
        player.stopVideo()

        if let window = containersWindow[screen] {
            window.orderOut(nil)
            containersWindow[screen] = nil
        }

        self.players[screen] = nil
    }
    
    @objc private func playWallpaper(isFirstStart: Bool = false) {
        
        let screens = screenManager?.screens
        
        for screen in screens ?? [] {
            if isFirstStart || ((currentWallpapers[screen]?.count ?? 0) > 1) {
                if (isPlaying) {
                    stopPlayingScreen(screen: screen)
                }
                startPlayingScreen(screen: screen)
            }
        }
        
    }
    
    private func startPlayingScreen(screen: NSScreen) {
        guard let wallpaper = getCurrentWallpaper(screen: screen) else
        {
            nextCurrentWallpaperIndex(screen: screen)
            return
        }
        
        startOnDesktop(screen: screen, wallpaper: wallpaper)
        setStaticWallpaper(screen: screen, wallpaper: wallpaper)
        
        nextCurrentWallpaperIndex(screen: screen)
        
        isPlaying = true
    }
    
    private func setCurrentWallpaperIndex(screen: NSScreen, index: Int) {
        currentWallpaperIndexes[screen] = index
    }
    
    private func nextCurrentWallpaperIndex(screen: NSScreen) {
        if (currentWallpaperIndexes[screen] == nil) {
            setCurrentWallpaperIndex(screen: screen, index: 0)
            print("nextCurrentWallpaperIndex:: Screen(\(screen.localizedName)) index was nil, init as 0")
            return
        }
        
        if ((currentWallpaperIndexes[screen] ?? 0) + 1 >= (currentWallpapers[screen]?.count ?? 0)) {
            setCurrentWallpaperIndex(screen: screen, index: 0)
            print("nextCurrentWallpaperIndex:: Screen(\(screen.localizedName)) index was more than wallpapers count, set as 0")
            return
        }
        
        let nextIndex = currentWallpaperIndexes[screen]! + 1
        setCurrentWallpaperIndex(screen: screen, index: nextIndex)
        print("nextCurrentWallpaperIndex:: Screen(\(screen.localizedName)) set as \(currentWallpaperIndexes[screen]!)")
        
    }
    
    public func getCurrentWallpaper(screen: NSScreen) -> Wallpaper? {
        
        if (currentWallpapers[screen] == nil) {
            currentWallpapers[screen] = []
            print("getCurrentWallpaper:: Screen(\(screen.localizedName)) current wallpapers initialized, return nil")
            return nil
        }
        
        if currentWallpapers[screen]?.count == 0 {
            print("getCurrentWallpaper:: Screen(\(screen.localizedName)) current wallpapers is empty, return nil")
            return nil
        }
        
        let currentIndex = currentWallpaperIndexes[screen] ?? 0
        
        print("getCurrentWallpaper:: Screen(\(screen.localizedName)) Current wallpaper index is \(currentIndex)")
        
        if currentIndex >= currentWallpapers[screen]!.count {
            print("getCurrentWallpaper:: Screen(\(screen.localizedName)) current wallpaper index more than wallpapers count, return nil")
            return nil
        }
        
        let wallpaper = currentWallpapers[screen]![currentIndex]
        print("getCurrentWallpaper:: Screen(\(screen.localizedName)) Wallpaper is found by index")
        
        return wallpaper
        
    }
    
    private func startOnDesktop(screen: NSScreen, wallpaper: Wallpaper) {
                
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
        
        containersWindow[screen] = window
        players[screen] = view
    }
    
    private func setStaticWallpaper(screen: NSScreen, wallpaper: Wallpaper) {
        StaticWallpaperUtil.setWallpaper(imageURL: wallpaper.imageURL!, screen: screen)
    }
    
    func selectWallpaper(_ wallpaper: Wallpaper, screen: NSScreen) {
        
        let wallpapers = currentWallpapers[screen] ?? []

        if wallpapers.count >= MAX_CURRENT_WALLPAPERS {
            print("Превышен максимум текущих обоев (\(MAX_CURRENT_WALLPAPERS)) для экрана \(screen.localizedName)")
            return
        }
        
        if (currentWallpapers[screen]?.contains(where: { $0.id == wallpaper.id }) == true) {
            return
        }
        
        currentWallpapers[screen]?.insert(wallpaper, at: 0)
        setCurrentWallpaperIndex(screen: screen, index: 0)
        
        if isPlaying {
            stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.start()
            }
        }
        self.saveWallpapers()
        completeScreensImages()
        print("✅ Selected wallpaper: \(wallpaper.title)")
        print("✅ Current wallpapers: \(currentWallpapers[screen]?.count)")
    }
    
    func removeFromAvailable(_ wallpaper: Wallpaper) {
        availableWallpapers.removeAll { $0.id == wallpaper.id }
        print("🗑 Removed from available: \(wallpaper.title)")
        
        let screens = screenManager?.screens
        
        for screen in screens ?? [] {
            currentWallpapers[screen]?.removeAll { $0.id == wallpaper.id }
            setCurrentWallpaperIndex(screen: screen, index: 0)
        }
        saveWallpapers()
        stop()
        start()
    }
    
    
    func loadAvailableWallpapers() {
        
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
    
    func loadCurrentWallpapers() {
        
        guard let data = UserDefaults.standard.data(forKey: "currentWallpapers_v2") else {
            print("ℹ️ No current wallpapers")
            return
        }
        
        do {
            let currentWallpapersData = try JSONDecoder().decode([String: [Wallpaper]].self, from: data)
            
            let screens = screenManager?.screens
            
            for (screenIdentifier, wallpapers) in currentWallpapersData {
                if let screen = screens?.first(where: {
                    $0.localizedName == screenIdentifier
                }) {
                    self.currentWallpapers[screen] = wallpapers
                }
            }
            
            var wallpapersCounter = 0
                                  
            for (screen, wallpapers) in currentWallpapers {
                
                var validWallpapers: [Wallpaper] = []
                
                for wallpaper in wallpapers {
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
                
                if (validWallpapers.count != wallpapers.count) {
                    currentWallpapers[screen] = validWallpapers
                    print("Use valid wallpapers: \(validWallpapers.count)")
                }
                
                wallpapersCounter += currentWallpapers[screen]?.count ?? 0
                
            }
            
            print("Loaded wallpapers count: \(wallpapersCounter)")
            
        } catch {
            print("❌ Loading wallpapers failed: \(error)")
        }
        
    }
    
    func saveAvailableWallpapers() {
        
        do {
            let data = try JSONEncoder().encode(availableWallpapers)
            UserDefaults.standard.set(data, forKey: "savedWallpapers")
            print("Wallpaper's saved count: \(availableWallpapers.count)")
        } catch {
            print("Save error!")
        }
        
    }
    
    func saveCurrentWallpapers() {
       do {
           let screenWallpaperData = currentWallpapers.reduce([String: [Wallpaper]]()) { dict, entry in
               var dict = dict
               dict["\(entry.key.localizedName)"] = entry.value
               return dict
           }
           
           let data = try JSONEncoder().encode(screenWallpaperData)
           UserDefaults.standard.set(data, forKey: "currentWallpapers_v2")
       } catch {
           print("Save error!")
       }
   }
    
    func removeFromCurrent(_ wallpaper: Wallpaper, screen: NSScreen) {
        currentWallpapers[screen]?.removeAll { $0.id == wallpaper.id }
        setCurrentWallpaperIndex(screen: screen, index: 0)
        saveWallpapers()
        print("🗑 Removed from current: \(wallpaper.title)")
        stop()
        start()
    }
    
    func reboot() {
        
        stop()
        
        // Clean all wallpapers
        let screens = screenManager?.screens ?? []
        for screen in screens {
            currentWallpapers[screen]?.removeAll()
        }
        availableWallpapers.removeAll()
        saveWallpapers()
        
        // Clean time to change
        timeToChange = 0
        saveTimeToChange()
        
    }
}
