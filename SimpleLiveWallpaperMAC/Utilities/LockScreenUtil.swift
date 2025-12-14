//
//  LockScreenUtil.swift
//  SimpleLiveWallpaperMAC
//
//  Created by Вадим Вехов on 14.12.2025.
//
import AVFoundation
import Cocoa

final class LockScreenUtil {

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
    static func setLockScreen(imageURL: URL) {
        let lockScreenPath = "/Library/Caches/com.apple.desktop.admin.png"

        // Экранируем пути
        let src = imageURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let dst = lockScreenPath.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        do shell script "cp \\"\(src)\\" \\"\(dst)\\"" with administrator privileges
        """

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)

        if let err = error {
            print("❌ AppleScript error:", err)
        } else {
            print("✅ Lock Screen image installed")
        }
    }

    
    /// Основной метод: из видео → Lock Screen
    static func setLockScreen(fromVideo url: URL) {
        guard let tempFile = generateImageFile(from: url) else { return }
        setLockScreen(imageURL: tempFile)
    }
}
