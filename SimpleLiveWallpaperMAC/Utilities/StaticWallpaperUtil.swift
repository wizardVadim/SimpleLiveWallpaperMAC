//
//  StaticWallpaperUtil.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 14.12.2025.
//
import AVFoundation
import Cocoa

final class StaticWallpaperUtil {

    /// Генерируем кадр из видео и сохраняем как PNG
    static func generateImageFile(from url: URL, at time: CMTime = CMTimeMake(value: 1, timescale: 1)) -> URL? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFile = tempDir.appendingPathComponent("lockscreen_wallpaper.png")
            
            if let tiffData = nsImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: tempFile, options: .atomic)
                return tempFile
            }
        } catch {
            print("❌ Error generating image: \(error)")
        }
        return nil
    }
    
    /// Устанавливает изображение на Lock Screen (через системный кэш)
    static func setWallpaper(imageURL: URL) {
        let workspace = NSWorkspace.shared
        guard let screen = NSScreen.main else { return }
        
        do {
            try workspace.setDesktopImageURL(imageURL, for: screen, options: [:])
        } catch (let error) {
            print("Не удалось установить обои.")
        }
    }

    
    /// Основной метод: из видео → Lock Screen
    static func setWallpaper(fromVideo url: URL) {
        guard let tempFile = generateImageFile(from: url) else { return }
        setWallpaper(imageURL: tempFile)
        print("desktop wallpapers set")
    }
}
