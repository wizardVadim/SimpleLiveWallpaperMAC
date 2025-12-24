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
            
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let fileName = "lockscreen_wallpaper_\(timestamp).png"
            
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempFile = tempDir.appendingPathComponent(fileName)
            
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
    
    static func setWallpaper(imageURL: URL, screen: NSScreen) {
        let workspace = NSWorkspace.shared // TODO: We can get current desktop image to view that
        
        do {
            try workspace.setDesktopImageURL(imageURL, for: screen, options: [:])
        } catch (let error) {
            print("Can't set static wallpaper.")
        }
    }
    
    static func setWallpaper(fromVideo url: URL, screen: NSScreen) {
        guard let tempFile = generateImageFile(from: url) else { return }
        setWallpaper(imageURL: tempFile, screen: screen)
        print("desktop wallpapers set")
    }
}
